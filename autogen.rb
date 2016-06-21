def gen_model(t)
  model = t.singularize
  puts "rails g model #{model}"
  `rails g model #{model}`
end

def gen_scaffold(t)
  clazz_name = t.camelize.singularize
  clazz = Object.const_get(clazz_name)
  cols = clazz.columns.delete_if{|x| x.name=="created_at" || x.name=="updated_at"}
  fields = cols.map{|x| x.name+":"+x.type.to_s}.join(" ")
  puts "rails g scaffold #{clazz} #{fields} -f"
  `rails g scaffold #{clazz} #{fields} -f`  
end

def fix_table_name(t)
  single = t.singularize
  if single == t || single+"s" != t #表的名字是单数，或者是类似y结尾的不规则英文复数规则
    filename = "app/models/#{single}.rb"
    `rpl "\nend" "\n  self.table_name = '#{t}'\nend" #{filename}`
  end
  if t.singularize+"s" != t
    
  end
end

ActiveRecord::Base.connection.tables.each do |t|
  next if t.match /_\d/ #表的名字类似goodslist_20151127
  gen_model(t)
  fix_table_name(t)
  gen_scaffold(t)
  fix_table_name(t)
end




