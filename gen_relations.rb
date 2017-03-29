require_relative 'extra_databases'
require_relative 'insert_into_file'

$belongs={}
$belongs2={}
$many={}

$tables.each do |t|
  if t.singularize.pluralize != t
    puts "警告： 表名#{t}的复数规则有问题"
  end
end

def table_exsits?(str)
  $tables.find {|x| x==str.pluralize} != nil
end

def test_relation(table_name,col_name,col_prefix)
  single = table_name.singularize
  if table_exsits?(col_prefix)
    if col_prefix!=col_prefix.pluralize.singularize
      puts "警告： 外键#{col_name}应该使用单数表名#{col_prefix.singularize}"
    end
    clazz = Object.const_get(col_prefix.pluralize.singularize.camelize)
    puts "  found: #{table_name} -> #{col_prefix}" if $verbose
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
  else
    puts "  not found: #{table_name} -> #{col_prefix}"  if $verbose
    return false
  end
end

def find_relation(t)
  single = t.singularize
  clazz_name = t.camelize.singularize
  clazz = Object.const_get(clazz_name)
  cols = clazz.columns.find_all{|x| x.name[-3..-1]=="_id"}
  puts "try finding relationship: #{t}"  if $verbose
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

ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
$tables.each do |t|
  begin
    find_relation(t)
  rescue Exception => e
    # 表的字段名包含中文等问题，导致scaffold生成失败时，会导致这里执行失败
    puts e
  end
end


require_relative 'custom_fk'
merge_custome_relation

File.open('./public/belongs.yaml', 'w') {|f| f.write(YAML.dump($belongs2)) }
File.open('./public/many.yaml', 'w') {|f| f.write(YAML.dump($many)) }
#TODO: 是否不放在public目录下，提高安全性。目前在发布环境下，不提供静态文件下载，所以没有安全性漏洞。但是这也要求不能通过nginx等提供public目录的访问。


$belongs.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    if x.class==String
      insert_into_file(filename, "\n  belongs_to :#{x}", "\nend", false)
    else
      col_prefix,clazz,col_name = x
      insert_into_file(filename, "\n  belongs_to :#{col_prefix}, class_name: '#{clazz.name}', foreign_key: '#{col_name}' ", "\nend", false)
    end
  end
end

$many2.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    clazz, col_name, _ = x
    tt = clazz.name.underscore.pluralize
    insert_into_file(filename, "\n  has_many :#{tt}, class_name: '#{clazz.name}', foreign_key: '#{col_name}'", "\nend", false)
  end
end

$many.each do |key, arr|
  filename = "app/models/#{key}.rb"
  arr.each do |x|
    next if $many2[key] && $many2[key].find{|arr3| arr3[2]==x}
    insert_into_file(filename, "\n  has_many :#{x.pluralize}", "\nend", false)
  end
end


def extra_belongs_class
  $belongs.map do |key, arr|
    arr2 = arr.map do |x|
      if x.class==String
        nil
      else
        col_prefix,clazz,col_name = x
        [col_name, clazz.name]
      end
    end.delete_if{|x| x.nil?}
    [key, arr2.to_h]
  end.to_h
end

File.open('./public/belongs_class.yaml', 'w') do |f| 
  f.write(YAML.dump(extra_belongs_class))
end



