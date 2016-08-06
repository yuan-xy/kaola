json.merge! @<%= singular_table_name %>.attributes
$belongs['<%= singular_table_name %>'].try(:each) do |x|
	json.set! x, @<%= singular_table_name %>.send(x).try(:attributes)
end

if params[:many]=="1"
  $many['<%= singular_table_name %>'].try(:each) do |x|
    xs = x.pluralize
  	json.set! xs do 
  		json.array!(@<%= singular_table_name %>.send(xs)) do |arr|
  		  json.merge! arr.attributes
  		end
  	end
  end
end

if params[:many] && params[:many].size>1
  params[:many].split(",").each do |x|
  	json.set! x do 
  		json.array!(@<%= singular_table_name %>.send(x)) do |arr|
  		  json.merge! arr.attributes
  		end
  	end
  end
end