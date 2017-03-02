class BulkController < ApplicationController
  
  def file_template
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    clazz = Object.const_get params[:table].singularize.camelize
    clazz.column_names.each_with_index do |col,i|
      worksheet.add_cell(0, i, col)
    end
    send_data workbook.stream.string,
              filename: "test.xlsx", disposition: 'attachment',
              type: "application/xlsx"
  end
  
  def file_upload
  end
  
  def import
    clazz = Object.const_get params[:table].singularize.camelize
    file = params[:file].tempfile
    if file.path.ends_with? 'xlsx'
      workbook = RubyXL::Parser.parse(file)
      sheet=workbook.worksheets[0]
      size = sheet[0].size
      arr = []
      (0..size-1).each do |x|
        v= sheet[0][x].value
        name = clazz.column_names.find{|col| col==v || clazz.human_attribute_name(col) == v}
        raise "#{v}对应的数据库列不存在" unless name
        arr << name
      end
      ret = []
      ActiveRecord::Base.transaction do
        (1..(sheet.count-1)).each do |row|
          obj = clazz.new
          arr.each_with_index{|name,i| obj.send(name+"=", sheet[row][i].try(:value))}
          obj.save!
          ret << obj
        end
        #TODO: 似乎事务不起作用
      end
      render :json => ret
    elsif file.path.ends_with? 'xls'
      raise '暂不支持xls后缀，请转化为xlsx后缀'
    else
      raise '只能导入excel格式文件'
    end
  end
  
  def batch
    raise "only support json input" unless request.format == 'application/json'
    ret = {"insert":[], "update":[], "delete":[]}
    ActiveRecord::Base.transaction do
      params[:insert].try(:each) do |t, arr|
        clazz = to_model(t)
        if clazz && arr.class == Array
          arr.each do |hash| 
            obj = clazz.new(hash.permit!).save!
            ret[:insert] << obj
          end
        end
      end
      params[:update].try(:each) do |t, arr|
        clazz = to_model(t)
        if clazz && arr.class == Array
          arr.each do |hash|
            id = hash[:id]
            hash.delete(:id)
            obj = clazz.find(id).update_attributes!(hash.permit!)
            ret[:update] << obj
          end
        end
      end
      params[:delete].try(:each) do |t, arr|
        clazz = to_model(t)
        if clazz && arr.class == Array
          arr.each do |id|
            obj = clazz.find(id).destroy
            ret[:delete] << obj
          end
        end
      end
    end    
    render :json => ret.to_json
  end
  
  private
  
  def to_model(tname)
    clazz_name = tname.camelize.singularize
    begin
      clazz = Object.const_get(clazz_name)
      if clazz.respond_to? "table_name"
        clazz
      else
        nil
      end
    rescue Exception => e
      nil
    end
  end
  
end
