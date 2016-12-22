require_relative 'extra_databases'
require_relative 'insert_into_file'
require 'pmap'
require 'etc'

def gen_scaffold(t)
  clazz_name = t.camelize.singularize
  cols = ActiveRecord::Base.connection.columns(t).delete_if{|x| x.name=="created_at" || x.name=="updated_at"}
  fields = cols.map{|x| x.name+":"+x.type.to_s}.join(" ")
  puts "rails g scaffold #{clazz_name} #{fields} -f" if $verbose
  system("rails g scaffold #{clazz_name} #{fields} -f > /dev/null")
end

def fix_primary_key(t)
  #TODO: 目前写死primary_key为id，以后也许可以自动检测
  # 对于数据库view类型的模型，必须手动设置primary_key。更好的方式是只有view执行这个方法。
  single = t.singularize
  filename = "app/models/#{single}.rb"
  insert_into_file(filename, "\n  self.primary_key = 'id'", "\nend", false)
end

def fix_table_name(t)
  single = t.singularize
  if single == t || single+"s" != t #表的名字是单数，或者是类似y结尾的不规则英文复数规则
    filename = "app/models/#{single}.rb"
    insert_into_file(filename, "\n  self.table_name = '#{t}'", "\nend", false)
  end
end

def fix_connection(t, extra_db)
  single = t.singularize
  filename = "app/models/#{single}.rb"
  str = "#{extra_db}_#{Rails.env}"
  insert_into_file(filename, "\n  establish_connection '#{str}'.to_sym", "\nend", false)
end

def proc_num
  ret = Etc.nprocessors
  ret = 20 if ret>20
  ret
end

def gen_db_tables(hash, re_try=true)
  errors = {}
  hash.each do |db, tables|
    errors[db] = []
    if db != :DEFAULT
      ActiveRecord::Base.establish_connection("#{db}_#{Rails.env}".to_sym)
    end
    tables.peach(proc_num) do |t|
      print '.' unless $verbose
      begin
        flag = gen_scaffold(t)
        unless flag
          errors[db] << t 
        end
      rescue Exception => e
        errors[db] << t
      end
      fix_primary_key(t)
      fix_table_name(t)
      fix_connection(t, db) if db != :DEFAULT
    end
  end
  if re_try
    puts "retry #{errors}" 
    gen_db_tables(errors, false)
  end
end
