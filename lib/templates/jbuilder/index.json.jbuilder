if params[:count]=="1"
	json.count @count
	json.data do
		json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
		  json.merge! <%= singular_table_name %>.try(:attributes)
		  $belongs['<%= singular_table_name %>'].try(:each) do |x|
		  	json.set! x, <%= singular_table_name %>.send(x).try(:attributes)
		  end
		  if params[:many] && params[:many].size>1
		    params[:many].split(",").each do |x|
		    	json.set! x do 
		    		json.array!(<%= singular_table_name %>.send(x)) do |arr|
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
	  $belongs['<%= singular_table_name %>'].try(:each) do |x|
	  	json.set! x, <%= singular_table_name %>.send(x).try(:attributes)
	  end
	  if params[:many] && params[:many].size>1
	    params[:many].split(",").each do |x|
	    	json.set! x do 
	    		json.array!(<%= singular_table_name %>.send(x)) do |arr|
	    		  json.merge! arr.try(:attributes)
	    		end
	    	end
	    end
	  end
	end
end




