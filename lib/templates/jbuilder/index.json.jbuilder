def func(json)
	json.array!(@<%= plural_table_name %>.each_with_index.to_a) do |(<%= singular_table_name %>, i)|
	  json.merge! <%= singular_table_name %>.try(:filter_attributes)
	  @belong_names.each do |name|
	    json.set! name, @belongs[i][name].try(:filter_attributes)
	  end
	  @many.try(:each) do |x,value|
    	json.set! x do 
    		json.array!(value[i]) do |arr|
    		  json.merge! arr
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




