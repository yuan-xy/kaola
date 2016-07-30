require_relative 'extra_databases'

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
end

def fix_connection(t, extra_db)
  single = t.singularize
  filename = "app/models/#{single}.rb"
  env_str = '#{Rails.env}'
  str = "#{extra_db}_#{env_str}"
  `rpl "\nend" '\n  establish_connection "#{str}".to_sym\nend' #{filename}`
end


ActiveRecord::Base.connection.tables.each do |t|
  next if t.match /_\d/ #表的名字类似goodslist_20151127
  gen_model(t)
  fix_table_name(t)
  gen_scaffold(t)
  fix_table_name(t)
end

$extra_databases.each do |extra|
  ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym).connection.tables.each do |t|
    next if t.match /_\d/ #表的名字类似goodslist_20151127
    gen_model(t)
    fix_table_name(t)
    gen_scaffold(t)
    fix_table_name(t)
    fix_connection(t, extra)
  end
end


$belongs={}
$many={}


def find_relation(t)
  return if t.match /_\d/ #表的名字类似goodslist_20151127
  single = t.singularize
  clazz_name = t.camelize.singularize
  clazz = Object.const_get(clazz_name)
  cols = clazz.columns.find_all{|x| x.name[-3..-1]=="_id"}
  puts "try finding relationship: #{t}"
  cols.each do |col|
    sname = col.name[0..-4]
    begin
      clazz = Object.const_get(sname.camelize)
      puts "  found: #{t} -> #{clazz}"
      if $belongs[single].nil?
          $belongs[single] = [sname]
      else
          $belongs[single] = $belongs[single] << sname
      end
      if $many[sname].nil?
          $many[sname] = [single]
      else
          $many[sname] = $many[sname] << single
      end
    rescue
      puts "  not found: #{t} -> #{col.name}"
    end
  end
end

ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym).connection.tables.each do |t|
  find_relation(t)
end

$extra_databases.each do |extra|
  ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym).connection.tables.each do |t|
    find_relation(t)
  end
end

File.open('./belongs.yaml', 'w') {|f| f.write(YAML.dump($belongs)) }
File.open('./many.yaml', 'w') {|f| f.write(YAML.dump($many)) }

$belongs.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    `rpl "\nend" "\n  belongs_to :#{x}\nend" #{filename}` 
  end
end

$many.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    `rpl "\nend" "\n  has_many :#{x.pluralize}\nend" #{filename}` 
  end
end


