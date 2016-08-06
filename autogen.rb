require_relative 'extra_databases'

def gen_scaffold(t)
  clazz_name = t.camelize.singularize
  cols = ActiveRecord::Base.connection.columns(t).delete_if{|x| x.name=="created_at" || x.name=="updated_at"}
  fields = cols.map{|x| x.name+":"+x.type.to_s}.join(" ")
  puts "rails g scaffold #{clazz_name} #{fields} -f"
  `rails g scaffold #{clazz_name} #{fields} -f`
  #下面的进程内执行方式，环境不对，没使用自定义的scaffold, 如何解决？
  #arr = [clazz_name, "-f", "--no-javascripts", "--no-helper","--no-stylesheets", "--orm=active_record"]
  #cols.map{|x| arr<<(x.name+":"+x.type.to_s)}
  #Rails::Generators.invoke "scaffold", arr, behavior: :invoke, destination_root: Rails.root
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
  gen_scaffold(t)
  fix_table_name(t)
end

$extra_databases.each do |extra|
  ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym).connection.tables.each do |t|
    next if t.match /_\d/ #表的名字类似goodslist_20151127
    gen_scaffold(t)
    fix_table_name(t)
    fix_connection(t, extra)
  end
end


$belongs={}
$belongs2={}
$many={}

def test_relation(table_name,col_name,col_prefix)
  single = table_name.singularize
  begin
    clazz = Object.const_get(col_prefix.camelize)
    puts "  found: #{table_name} -> #{clazz}"
    if col_prefix+"_id" == col_name
      if $belongs[single].nil?
          $belongs[single] = [col_prefix]
          $belongs2[single] = [col_prefix]
      else
          $belongs[single] = $belongs[single] << col_prefix
          $belongs2[single] = $belongs2[single] << col_prefix
      end
      if $many[col_prefix].nil?
          $many[col_prefix] = [single]
      else
          $many[col_prefix] = $many[col_prefix] << single
      end
    else
      col_prefix = col_name[0..-4]
      arr = [col_prefix,clazz,col_name]
      if $belongs[single].nil?
          $belongs[single] = [arr]
          $belongs2[single] = [col_prefix]
      else
          $belongs[single] = $belongs[single] << arr
          $belongs2[single] = $belongs2[single] << col_prefix
      end
      #一个模型有多个同一的表的外键时（前缀不同），不自动反向建立many关系
    end
    return true
  rescue Exception => e
    puts e
    puts "  not found: #{table_name} -> #{col_name}"
    return false
  end
end

def find_relation(t)
  return if t.match /_\d/ #表的名字类似goodslist_20151127
  single = t.singularize
  clazz_name = t.camelize.singularize
  clazz = Object.const_get(clazz_name)
  cols = clazz.columns.find_all{|x| x.name[-3..-1]=="_id"}
  puts "try finding relationship: #{t}"
  cols.each do |col|
    col_prefix = col.name[0..-4]
    while col_prefix.size>0
      break if test_relation(t,col.name,col_prefix)
      position = col_prefix.index("_")
      break unless position
      col_prefix = col_prefix[position+1..-1]
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


File.open('./belongs.yaml', 'w') {|f| f.write(YAML.dump($belongs2)) }
File.open('./many.yaml', 'w') {|f| f.write(YAML.dump($many)) }

$belongs.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    if x.class==String
      `rpl "\nend" "\n  belongs_to :#{x}\nend" #{filename}`
    else
      col_prefix,clazz,col_name = x
      `rpl "\nend" "\n  belongs_to :#{col_prefix}, class_name: '#{clazz.name}', foreign_key: '#{col_name}' \nend" #{filename}`     
    end
  end
end

$many.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    `rpl "\nend" "\n  has_many :#{x.pluralize}\nend" #{filename}` 
  end
end


