class ActiveRecord::Base
  
  def memcache_key
      self.class.memcache_key(id)
  end
  
  def self.memcache_key(id)
    "#{self.prefix}:#{self.name}:#{id}"
  end
  
  def self.memcache_key_nil?(key)
    key.ends_with? ":" 
  end
  
  def self.memceche_clazz_id(key)
    arr = key.split(":")
    clazz_name = arr[1]
    if arr.size==3
      id = arr[2] 
    elsif arr.size==2
      id = nil
    else
      raise "illegal memcache single key: #{key}"
    end
    [Object.const_get(clazz_name), id]
  end
  
  
  
  def self.memcache_load(id)
    cache = Rails.cache.read(memcache_key(id))
    memcache_load_nil(id, cache)
  end
    
  def self.memcache_load_nil(id, cache)
    raise 'null key not allowed' if id.nil? || id==''
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

  def self.memcache_load_true(id)
    ret = self.find_by_id(id)
    if ret.nil?
      ret = nil_value(id)
    end
    Rails.cache.write(memcache_key(id),ret)
    ret
  end
    
  def self.nil_value(id)
    {self => [id,nil]}
  end

  def self.multi_read_of_single_keys(keys)
    keys.uniq!
    keys.delete_if {|x| memcache_key_nil?(x) }
    caches = Rails.cache.read_multi(*keys)
    keys.each do |key|
      cache = caches[key]
      clazz, id = memceche_clazz_id(key)
      caches[key] = clazz.memcache_load_nil(id, cache)
    end
    caches
  end
   
end
