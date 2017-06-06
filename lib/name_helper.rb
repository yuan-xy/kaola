module NameHelper
  
  def get_table_class(table_name)
    Object.const_get(table_name.camelize.singularize)
  end
  
  def table_name_fix(table_name)
    get_table_class(table_name).table_name
  end
  
  def singular_table_name(clazz)
    clazz.name.singularize.underscore
  end
  

end