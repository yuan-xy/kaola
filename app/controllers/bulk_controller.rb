class BulkController < ApplicationController
  
  def batch
    raise "only support json input" unless request.format == 'application/json'
    ret = {"insert":[], "update":[], "delete":[]}
    ActiveRecord::Base.transaction do
      params[:insert].each do |t, arr|
        clazz = to_model(t)
        if clazz && arr.class == Array
          arr.each do |hash| 
            obj = clazz.new(hash.permit!).save!
            ret[:insert] << obj
          end
        end
      end
      params[:update].each do |t, arr|
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
      params[:delete].each do |t, arr|
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
