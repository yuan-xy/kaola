class ActiveRecord::Base
  
  def memcache_key
      self.class.memcache_key(id)
  end
  
  def self.memcache_key(id)
    "#{self.prefix}#{self.name} #{id}"
  end
  
  def self.memcache_load(id)
    cache = Rails.cache.read(memcache_key(id))
    memcache_load_nil(id, cache)
  end
    
  def self.memcache_load_nil(id, cache)
    if cache
      if cache == nil_value(id)
        nil
      else
        cache
      end
    else
      ret = self.find_by_id(id)
      if ret.nil?
        ret = nil_value(id)
      end
      Rails.cache.write(memcache_key(id),ret)
      ret
    end
  end
  
  def self.nil_value(id)
    {self => [id,nil]}
  end

   
end
