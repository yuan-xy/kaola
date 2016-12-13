class ActiveRecord::Base
  
  after_commit :clear_cache
  
  def clear_cache
    Rails.cache.delete(self.memcache_key)
    #Rails.cache.increment(self.class.timestamp_key)
    tm = Rails.cache.read(self.class.timestamp_key)
    tm = tm.to_i + 1
    Rails.cache.write(self.class.timestamp_key, tm)
  end
  
   
end
