class ActiveRecord::Base
  
  def nested_save(params)
    begin
      transaction do
        self.method(:save!).super_method.call  #确保只有一个事务
        single = self.class.name.underscore
        return true unless $many[single]
        $many[single].each do |x|
          xs = x.pluralize
          arr = params[xs]
          if arr && arr.size>0
            clazz = Object.const_get(x.camelize)
            arr.each do |hash|
              obj = clazz.new(hash.permit!)
              obj.tjb_role = self
              obj.method(:save!).super_method.call #如果存在外键，这里有死锁
            end
          end
        end
      end
      true
    rescue Exception => e
      puts e.backtrace
      logger.warn e
      false
    end
  end
  
end
