class ActiveRecord::Base

  def self.gen_workbook_template
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    self.column_names.each_with_index do |col,i|
      worksheet.add_cell(0, i, col)
    end
    workbook
  end
  
  def self.gen_workbook(list)
    workbook = gen_workbook_template
    worksheet = workbook[0]
    list.each_with_index do |obj, row|
      self.column_names.each_with_index do |col,i|
        worksheet.add_cell(row+1, i, obj.send(col))
      end
    end
    workbook
  end
   
end
