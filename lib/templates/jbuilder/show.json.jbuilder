json.merge! @<%= singular_table_name %>.attributes
$belongs['<%= singular_table_name %>'].try(:each) do |x|
	json.set! x, @<%= singular_table_name %>.request_cache_of_belongs_to(x).try(:attributes)
end

if params[:many]=="1" && Rails.env != "production"
  $many['<%= singular_table_name %>'].try(:each) do |x|
    xs = x.pluralize
  	json.set! xs do 
  		json.array!(@<%= singular_table_name %>.send(xs).limit(100)) do |arr|
  		  json.merge! arr.try(:attributes)
  		end
  	end
  end
end

if params[:many] && params[:many].size>1
  params[:many].split(",").each do |x|
  	json.set! x do 
  		json.array!(@<%= singular_table_name %>.send(x).limit(100)) do |arr|
  		  json.merge! arr.try(:attributes)
  		end
  	end
  end
end