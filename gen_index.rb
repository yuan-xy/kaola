require_relative 'extra_databases'

def human_table_name(t)
  clazz_name = t.camelize.singularize
  Object.const_get(clazz_name).connection.retrieve_table_comment(t)
end


File.open("public/index2.html","w") do |f|
  f.puts "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /></head><body>"
  f.puts "<table>"
  $database_tables.each do |db, tables|
    if db != :DEFAULT
      f.puts "<tr>"
      f.puts "<td>---database:#{db}---</td>"
      f.puts "</tr>"
      ActiveRecord::Base.establish_connection("#{db}_#{Rails.env}".to_sym)
    end
    tables.each do |t|
      f.puts "<tr>"
      f.puts "<td>#{human_table_name(t)}</td><td><a href='./#{t}'>#{t}</a></td>"
      f.puts "</tr>"
    end
    
  end
  f.puts "</table></body></html>"
end


hash = {"zh-CN"=>{"activerecord"=>{"models"=>{}, "attributes"=>{}}}}
$database_tables.each do |db, tables|
  if db != :DEFAULT
    ActiveRecord::Base.establish_connection("#{db}_#{Rails.env}".to_sym)
  else
    ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
  end
  ActiveRecord::Base.connection.retrieve_table_comments.each do |k,v|
    hash["zh-CN"]["activerecord"]["models"][k.singularize] = v
  end
  tables.each do |t|
    cols = ActiveRecord::Base.connection.retrieve_column_comments(t)
    cols.delete_if{|k,v| v.nil?}
    cols = cols.map{|k,v| [k.to_s, v.split(" ")[0]]}.to_h
    hash["zh-CN"]["activerecord"]["attributes"][t.singularize] = cols
  end
end

File.open('./config/locales/zh-CN.yml', 'w') do |f| 
  f.write(YAML.dump(hash))
end

