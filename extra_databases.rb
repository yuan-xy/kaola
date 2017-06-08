def get_extra_dbs
  env = "_#{Rails.env}"
  dbs = Rails.configuration.database_configuration.keys.find_all{|x| x.match(env)}
  size = env.size+1
  dbs.map{|x| x[0..-size]}
end

$extra_databases = get_extra_dbs


def is_ignore_table?(t)
  #表的名字类似goodslist_20151127, 属于备份表
  t.match /_\d/
end

def all_database_tables
  tables = {}
  ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  tables[:DEFAULT] = ActiveRecord::Base.connection.data_sources.delete_if{|t| is_ignore_table?(t)}
  $extra_databases.each do |extra|
    ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym)
    tables[extra] = ActiveRecord::Base.connection.data_sources.delete_if{|t| is_ignore_table?(t)}
  end
  ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  tables
end

$database_tables = all_database_tables

def all_tables
  $database_tables.values.flatten
end

def establish_conn(db)
  if db != :DEFAULT
    ActiveRecord::Base.establish_connection("#{db}_#{Rails.env}".to_sym)
  else
    ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  end
end

$tables = all_tables

class Hash
  def hmap(&block)
    self.inject({}){ |hash,(k,v)| hash.merge( block.call(k,v) ) }
  end
end


def new_tables
  $database_tables.hmap do |db, tables|
    nts = tables.map do |t|
        clazz_name = t.camelize.singularize
        begin
          clazz = Object.const_get(clazz_name)
          nil
        rescue Exception => e
          t
        end
    end
    { db => nts.delete_if{|x| x.nil?} }
  end
end


