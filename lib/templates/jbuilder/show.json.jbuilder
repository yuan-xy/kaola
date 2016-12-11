json.merge! @<%= singular_table_name %>.attributes
@<%= singular_table_name %>.belongs_to_multi_get.each do |k,v|
  json.set! k, v.try(:attributes)
end
		  
if params[:many]=="1" && Rails.env != "production"
  $many['<%= singular_table_name %>'].try(:each) do |x|
    xs = x.pluralize
  	json.set! xs do 
  		json.array!(@<%= singular_table_name %>.many_cache(xs)) do |arr|
  		  json.merge! arr.try(:attributes)
  		end
  	end
  end
end

if params[:many] && params[:many].size>1
  params[:many].split(",").each do |x|
  	json.set! x do 
  		json.array!(@<%= singular_table_name %>.many_cache(x)) do |arr|
  		  json.merge! arr.try(:attributes)
  		end
  	end
  end
end