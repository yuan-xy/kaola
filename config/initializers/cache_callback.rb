class ActiveRecord::Base
  
  after_commit :clear_cache
  
 
  def clear_cache
    Rails.logger.warn "after commit #{self}"
    Rails.cache.delete(memcache_key(self.class, self.id))
  end
  
  def memcache_key(clazz, id)
    "#{clazz.name} #{id}"
  end
  
  def memcache_load(clazz, id)
    cache = Rails.cache.read(memcache_key(clazz, id))
    if cache
      if cache == nil_value(clazz,id)
        nil
      else
        cache
      end
    else
      ret = clazz.find_by_id(id)
      if ret.nil?
        ret = nil_value(clazz,id)
      end
      Rails.cache.write(memcache_key(clazz, id),ret)
      ret
    end
  end
  
  def nil_value(clazz,id)
    {clazz => [id,nil]}
  end
  
  def request_cache_of_belongs_to(method_name)
    id = self.send(method_name+"_id")
    clazz_name = get_belongs_class_name(method_name)
    key = clazz_name+id.to_s
    return RequestStore.store[key] if RequestStore.store.has_key? key
    #ret = self.send(method_name)
    ret = memcache_load(Object.const_get(clazz_name), id)
    RequestStore.store[key] = ret
    ret
  end
  
  def get_belongs_class_name(method_name)
    hash = $belongs_class[self.class.name.underscore]
    clazz_name = hash[method_name+"_id"]
    return clazz_name if clazz_name
    method_name.camelize
  end
   
end
