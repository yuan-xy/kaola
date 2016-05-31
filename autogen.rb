ActiveRecord::Base.connection.tables.each do |t|
  model = t.singularize
  `rails g model #{model}`
end

ActiveRecord::Base.connection.tables.each do |t|
  clazz_name = t.camelize.singularize
  clazz = Object.const_get(clazz_name)
  cols = clazz.columns.delete_if{|x| x.name=="created_at" || x.name=="updated_at"}
  fields = cols.map{|x| x.name+":"+x.type.to_s}.join(" ")
  `rails g scaffold #{clazz} #{fields}`
end


