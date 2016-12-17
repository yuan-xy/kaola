require_relative 'gen_tables'

$verbose = ARGV.find{|x| x=="verbose"}

gen_db_tables(new_tables)

def no_relation
  ARGV.find{|x| x=="no_relation"}
end

require_relative 'gen_relations'  unless no_relation


