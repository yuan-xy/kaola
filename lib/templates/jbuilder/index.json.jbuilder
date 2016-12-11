if params[:count]=="1"
	json.count @count
	json.data do
		json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
		  json.merge! <%= singular_table_name %>.try(:attributes)
		  <%= singular_table_name %>.belongs_to_multi_get.each do |k,v|
		    json.set! k, v.try(:attributes)
		  end
		  if params[:many] && params[:many].size>1
		    params[:many].split(",").each do |x|
		    	json.set! x do 
		    		json.array!(<%= singular_table_name %>.send(x).limit(100)) do |arr|
		    		  json.merge! arr.try(:attributes)
		    		end
		    	end
		    end
		  end
		end
	end
else
	json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
	  json.merge! <%= singular_table_name %>.try(:attributes)
	  <%= singular_table_name %>.belongs_to_multi_get.each do |k,v|
	    json.set! k, v.try(:attributes)
	  end
	  if params[:many] && params[:many].size>1
	    params[:many].split(",").each do |x|
	    	json.set! x do 
	    		json.array!(<%= singular_table_name %>.send(x).limit(100)) do |arr|
	    		  json.merge! arr.try(:attributes)
	    		end
	    	end
	    end
	  end
	end
end




