class ActiveRecord::Base
  
  def get_create_sql
    self.class.arel_table.create_insert.tap do |im| 
      im.insert(self.send(:arel_attributes_with_values_for_create,
        self.class.attribute_names)) 
    end.to_sql
  end
  
  def nested_save(params)
    begin
      ret = [self]
      sqls = []
      transaction do
        #self.method(:save!).super_method.call  #确保只有一个事务, save默认启动一个事务
        sqls << self.get_create_sql
        single = self.class.name.underscore
        return ret unless $many[single]
        $many[single].each do |x|
          xs = x.pluralize
          arr = params[xs]
          if arr && arr.size>0
            clazz = Object.const_get(x.camelize)
            arr.each do |hash|
              obj = clazz.new(hash.permit!)
              obj.method("#{single}_id=").call(self.id)
              #obj.method(:save!).super_method.call #如果存在外键，这里有死锁
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
