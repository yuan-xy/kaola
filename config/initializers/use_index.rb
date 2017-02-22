class ActiveRecord::Base

  def self.use_index(index)
    return unless index
    raise "index str:#{index} is too long" if index.size>40
    from("#{self.table_name} USE INDEX(#{index})")
  end
   
end
