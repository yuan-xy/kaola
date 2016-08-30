if params[:count]=="1"
	json.count @count
	json.data do
		json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
		  json.merge! <%= singular_table_name %>.try(:attributes)
		  $belongs['<%= singular_table_name %>'].try(:each) do |x|
		  	json.set! x, <%= singular_table_name %>.send(x).try(:attributes)
		  end
		end
	end
else
	json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
	  json.merge! <%= singular_table_name %>.try(:attributes)
	  $belongs['<%= singular_table_name %>'].try(:each) do |x|
	  	json.set! x, <%= singular_table_name %>.send(x).try(:attributes)
	  end
	end
end




