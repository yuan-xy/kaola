def get_extra_dbs
  dbs = Rails.configuration.database_configuration.keys.find_all{|x| x.match("_development")}
  size = "_development".size+1
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
  tables[:DEFAULT] = ActiveRecord::Base.connection.tables.delete_if{|t| is_ignore_table?(t)}
  $extra_databases.each do |extra|
    ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym)
    tables[extra] = ActiveRecord::Base.connection.tables.delete_if{|t| is_ignore_table?(t)}
  end
  ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  tables
end

$database_tables = all_database_tables

def all_tables
  $database_tables.values.flatten
end

$tables = all_tables
