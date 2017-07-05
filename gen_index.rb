require_relative 'extra_databases'

def human_table_name(t)
  begin
    clazz_name = t.camelize.singularize
    Object.const_get(clazz_name).connection.retrieve_table_comment(t)
  rescue Exception => e
    t
  end
end


File.open("public/index2.html","w") do |f|
  f.puts "<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' /></head><body>"
  f.puts "<table>"
  $database_tables.each do |db, tables|
    establish_conn(db)
    if db != :DEFAULT
      f.puts "<tr>"
      f.puts "<td>---database:#{db}---</td>"
      f.puts "</tr>"
    end
    tables.each do |t|
      f.puts "<tr>"
      f.puts "<td>#{human_table_name(t)}</td><td><a href='./#{t.pluralize}'>#{t}</a></td><td><a href='./#{t.pluralize}.json'>#{t.pluralize}.json</a></td>"
      f.puts "</tr>"
    end
    
  end
  f.puts "</table></body></html>"
end


hash = {"zh-CN"=>{"activerecord"=>{"models"=>{}, "attributes"=>{}}}}
$database_tables.each do |db, tables|
  establish_conn(db)
  ActiveRecord::Base.connection.retrieve_table_comments.each do |k,v|
    hash["zh-CN"]["activerecord"]["models"][k.singularize] = v
  end
  tables.each do |t|
    cols = ActiveRecord::Base.connection.retrieve_column_comments(t)
    colhash = {}
    cols.each do |k,v|
      k = k.to_s
      if v.nil?
        colhash[k] = k
      else
        colhash[k] = v.split(" ")[0]
      end
    end
    hash["zh-CN"]["activerecord"]["attributes"][t.singularize] = colhash
  end
end

File.open('./config/locales/zh-CN.yml', 'w') do |f| 
  f.write(YAML.dump(hash))
end

