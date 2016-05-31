ActiveRecord::Base.connection.tables.each do |t|
 clazz = t.camelize
 `rails g scaffold #{clazz} id:int`
end

