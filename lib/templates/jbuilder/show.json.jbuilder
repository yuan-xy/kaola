json.merge! @<%= singular_table_name %>.attributes
$belongs['<%= singular_table_name %>'].try(:each) do |x|
	json.set! x, @<%= singular_table_name %>.send(x).attributes
end
#$many['<%= singular_table_name %>'].try(:each) do |x|
#	json.set! x do 
#		json.array!(@<%= singular_table_name %>.send(x.pluralize)) do |arr|
#		  json.merge! arr.attributes
#		end
#	end
#end

