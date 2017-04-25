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

def fix_primary_key(t, id='id')
  single = t.singularize
  filename = "app/models/#{single}.rb"
  insert_into_file(filename, "\n  self.primary_key = '"+id+"'", "\nend", false)
end

def try_fix_primary_key(t, views)
  clazz = Object.const_get(t.singularize.camelize) 
  if clazz.primary_key
    if views.find{|x| x==t}
      fix_primary_key(t, clazz.primary_key)  #activerecord库对视图的主键处理有bug，所以这里强制设置视图的主键
    end
    return
  end
  if clazz.attribute_names.find{|x| x=='id'}
    fix_primary_key(t)
    return
  end
  id = clazz.attribute_names.find{|x| x.ends_with? '_id'}
  if id
    puts "警告：表#{t}的主键没有，启发式规则设置为#{id}"
    fix_primary_key(t, id)
  else
    puts "警告： 表#{t}不存在主键"
  end
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
  str = extra_db+'_#{Rails.env}'
  insert_into_file(filename, "\n  establish_connection \"#{str}\".to_sym", "\nend", false)
end

def proc_num
  ret = Etc.nprocessors
  ret = 4 if ret>4
  ret
end

def gen_db_tables(hash, re_try=true, parallel=true)
  errors = {}
  hash.each do |db, tables|
    establish_conn(db)
    errors[db] = []
    proc = Proc.new do |t|
      print '.' unless $verbose
      succ = true
      begin
        flag = gen_scaffold(t)
        unless flag
          errors[db] << t 
          succ = false
        end
      rescue Exception => e
        errors[db] << t
        succ = false
      end
      if succ
        fix_table_name(t)
        fix_connection(t, db) if db != :DEFAULT
      end
    end
    if parallel
      tables.peach(proc_num, &proc)
    else
      tables.each &proc
    end
  end
  if re_try && errors.size>0
    puts "\nretry #{errors}" 
    gen_db_tables(errors, false, false)
  end
  if re_try # 表示首次调用，非递归
    hash.each do |db, tables|
      establish_conn(db)
      views = ActiveRecord::Base.connection.retrieve_views
      tables.each{|t| try_fix_primary_key(t, views) }
    end
  end
end
