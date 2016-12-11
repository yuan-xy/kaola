json.merge! @<%= singular_table_name %>.attributes
@<%= singular_table_name %>.belongs_to_multi_get.each do |k,v|
  json.set! k, v.try(:attributes)
end

@many.try(:each) do |x,value|
  	json.set! x do 
  		json.array!(value) do |arr|
  		  json.merge! arr.try(:attributes)
  		end
  	end
end