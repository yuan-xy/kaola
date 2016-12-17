require_relative 'gen_tables'

$verbose = ARGV.find{|x| x=="verbose"}

gen_db_tables($database_tables)

require_relative 'gen_relations'
