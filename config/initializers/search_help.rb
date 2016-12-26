class ActionController::Base
  
  def check_search_param_exsit(hash,clazz)
    attrs = clazz.attribute_names
    %w{like date range in cmp}.each do |op|
      next unless hash[op]
      hash[op].each{|k,v| check_keys_exist(k, attrs, clazz)}
      hash.delete(op)
    end
    hash.each{|k,v| check_keys_exist(k, attrs, clazz)}
  end
  
  def check_keys_exist(keys, attrs, clazz)
    if keys.index(",")
      keys.split(",").each{|x| check_field_exist(x, attrs)}
    elsif keys.index(".")
      model, field = keys.split(".")
      check_field_exist(model+"_id", attrs)
      clazz_name = clazz.get_belongs_class_name(model)
      check_field_exist(field, Object.const_get(clazz_name).attribute_names)
    else
      check_field_exist(keys, attrs)
    end
  end
  
  def check_field_exist(field, attrs)
    find = attrs.find{|x| x==field}
    raise "field:#{field} doesn't exists." unless find
  end
  
end