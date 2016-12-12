def get_extra_dbs
  dbs = Rails.configuration.database_configuration.keys.find_all{|x| x.match("_development")}
  size = "_development".size+1
  dbs.map{|x| x[0..-size]}
end

$extra_databases = get_extra_dbs

def all_database_tables
  tables = {}
  ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  tables[:DEFAULT] = ActiveRecord::Base.connection.tables
  $extra_databases.each do |extra|
    ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym)
    tables[extra] = ActiveRecord::Base.connection.tables
  end
  ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  tables
end

$database_tables = all_database_tables

def all_tables
  $database_tables.values.flatten
end

$tables = all_tables
