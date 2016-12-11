class ActiveRecord::Base
  
  after_commit :clear_cache
  
 
  def clear_cache
    Rails.logger.warn "after commit #{self}"
    Rails.cache.delete(memcache_key(self.class, self.id))
    Rails.cache.increment("timestamp:#{self.class.name}")
  end
  
  def self.get_class_timestamp(class_name)
    Rails.cache.fetch("timestamp:#{class_name}") do
      "1"
    end    
  end
  
  def self.request_cache_of_class_timestamp(class_name)
    key = "timestamp:#{class_name}"
    return RequestStore.store[key] if RequestStore.store.has_key? key
    ret = get_class_timestamp(class_name)   
    RequestStore.store[key] = ret
    ret
  end
  
  def many_cache(table)
    key = many_cache_key(table)
    Rails.cache.fetch(key) do
      self.send(table).limit(100).to_a
    end
  end
  
  def many_cache_key(table)
    class_name = table.singularize.camelize
    timestamp = self.class.request_cache_of_class_timestamp(class_name)
    "#{table} #{timestamp} #{self.class.name} #{self.id}"
  end
  
  
  def belongs_to_multi_get
    tname = self.class.name.underscore
    return {} if $belongs[tname].nil?
    ret = {}
	  request_caches = $belongs[tname].map do |x|
      cache,flag = self.request_cache_of_belongs_to_only(x)
      [x,cache,flag]
	  end
    request_caches.each {|x, cache,flag| ret[x]=cache if flag}
    memcache_names = request_caches.delete_if{|x, cache,flag| flag}.map{|x, cache,flag| x}
    return ret if memcache_names.empty?
    mem_caches = memcache_belongs_to_multi(memcache_names)
    mem_caches.each do |k, v|
      RequestStore.store[request_cache_key_of_belongs(k)] = v
    end
    ret.merge! mem_caches
    ret
  end
  
  def memcache_belongs_to_multi(arr)
    ret = {}
    names = arr.map{|x| memcache_cache_key_of_belongs(x)}
    caches = Rails.cache.read_multi(*names)
    arr.each_with_index do |method_name,i|
      cache = caches[names[i]]
      clazz, id = clazz_id_of_belongs(method_name)
      ret[arr[i]] = memcache_load0(clazz, id, cache)
    end
    ret
  end
  
  def memcache_key(clazz, id)
    "#{clazz.name} #{id}"
  end
  
  def memcache_load(clazz, id)
    cache = Rails.cache.read(memcache_key(clazz, id))
    memcache_load0(clazz, id, cache)
  end
  
  def memcache_load0(clazz, id, cache)
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
  
  def request_cache_key_of_belongs(method_name)
    id = self.send(method_name+"_id")
    clazz_name = get_belongs_class_name(method_name)
    clazz_name+id.to_s
  end
  
  def memcache_cache_key_of_belongs(method_name)
    clazz, id = clazz_id_of_belongs(method_name)
    memcache_key(clazz, id)
  end

  def request_cache_of_belongs_to_only(method_name)
    key = request_cache_key_of_belongs(method_name)
    return [RequestStore.store[key], RequestStore.store.has_key?(key)]
  end
    
  def cache_of_belongs_to(method_name)
    key = request_cache_key_of_belongs(method_name)
    return RequestStore.store[key] if RequestStore.store.has_key? key
    id = self.send(method_name+"_id")
    clazz_name = get_belongs_class_name(method_name)
    ret = memcache_load(Object.const_get(clazz_name), id)
    RequestStore.store[key] = ret
    ret
  end
  
  def clazz_id_of_belongs(method_name)
    id = self.send(method_name+"_id")
    clazz_name = get_belongs_class_name(method_name)
    [Object.const_get(clazz_name), id]
  end  
  
  def get_belongs_class_name(method_name)
    hash = $belongs_class[self.class.name.underscore]
    clazz_name = hash[method_name+"_id"]
    return clazz_name if clazz_name
    method_name.camelize
  end
   
end
