class ActiveRecord::Base
  
  def get_create_sql
    self.class.arel_table.create_insert.tap do |im| 
      im.insert(self.send(:arel_attributes_with_values_for_create,
        self.class.attribute_names)) 
    end.to_sql
  end
  
  def need_nested_save(params)
    single = self.class.name.underscore
    return false  unless $many[single]
    $many[single].each do |x|
      xs = x.pluralize
      arr = params[xs]
      return true if arr && arr.size>0
    end
    false
  end
  
  def need_batch_save(params)
    tname = self.class.table_name
    return true  if params[tname]
    false
  end
  
  def batch_save(params)
    ret = []
    tname = self.class.table_name
    params[tname].each do |hash|
      ret << self.class.new(hash.permit!)
    end
    self.class.import ret
    ret
  end
  
  def nested_save(params)
    return batch_save(params) if need_batch_save(params)
    unless need_nested_save(params)
      self.save!
      return self
    end
    begin
      ret = [self]
      sqls = []
      transaction do
        sqls << self.get_create_sql
        single = self.class.name.underscore
        $many[single].each do |x|
          xs = x.pluralize
          arr = params[xs]
          if arr && arr.size>0
            clazz = Object.const_get(x.camelize)
            arr.each do |hash|
              obj = clazz.new(hash.permit!)
              obj.method("#{single}_id=").call(self.id)
              sqls << obj.get_create_sql
              ret << obj
            end
          end
        end
        sqls.each{|sql| self.class.connection.execute(sql)}
      end
      ret
    rescue Exception => e
      puts e.backtrace
      logger.warn e
      self.errors.add(:name, message:e.to_s)
      nil
    end
  end
  
end
