def func(json)
	json.array!(@<%= plural_table_name %>.each_with_index.to_a) do |(<%= singular_table_name %>, i)|
	  json.merge! <%= singular_table_name %>.try(:attributes)
	  <%= singular_table_name %>.belongs_to_multi_get.each do |k,v|
	    json.set! k, v.try(:attributes)
	  end
	  @many.each do |x,value|
    	json.set! x do 
    		json.array!(value[i]) do |arr|
    		  json.merge! arr.try(:attributes)
    		end
    	end
	  end
	end
end

if params[:count]=="1"
	json.count @count
	json.data do
	  func(json)
	end
else
	func(json)
end




