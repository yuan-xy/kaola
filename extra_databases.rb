def get_extra_dbs
  dbs = Rails.configuration.database_configuration.keys.find_all{|x| x.match("_development")}
  size = "_development".size+1
  dbs.map{|x| x[0..-size]}
end
$extra_databases = get_extra_dbs