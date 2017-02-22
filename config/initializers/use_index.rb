class ActiveRecord::Base

  def self.use_index(index)
    from("#{self.table_name} USE INDEX(#{index})")
  end
   
end
