require_relative 'gen_tables'

$verbose = ARGV.find{|x| x=="verbose"}


File.truncate('config/route_codegen.rb', 0)

gen_db_tables($database_tables, true, false)

require_relative 'gen_relations'

def uniq_routes
  res = []
  output = []
  begin_res = 0
  File.open('config/routes.rb').each do |line|
    if begin_res == 0
      if line =~ /resource/
        begin_res = 1
        res << line
      else
        output << line
      end
    elsif begin_res == 1
      if line =~ /resource/
        res << line
      else
        begin_res = 2
        res.sort.uniq.each {|x| output << x}
        output << line
      end
    elsif begin_res == 2
      output << line
    end
  end
  File.open('config/routes.rb', "wb") do |file| 
    output.each {|x| file.write(x) }
  end
end

uniq_routes
