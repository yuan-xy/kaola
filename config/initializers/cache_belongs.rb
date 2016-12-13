class ActiveRecord::Base
  
  # 批量获取本对象所有的belong_to对象，基于localcache和memcache两层的查找方式
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
  
  
  # 批量获取多个belong_to方法指向的对象
  def memcache_belongs_to_multi(methods)
    ret = {}
    names = methods.map{|x| memcache_cache_key_of_belongs(x)}
    caches = Rails.cache.read_multi(*names)
    methods.each_with_index do |method_name,i|
      cache = caches[names[i]]
      clazz, id = clazz_id_of_belongs(method_name)
      ret[methods[i]] = clazz.memcache_load_nil(id, cache)
    end
    ret
  end
  
  def request_cache_key_of_belongs(method_name)
    id = self.send(method_name+"_id")
    clazz_name = get_belongs_class_name(method_name)
    clazz_name+id.to_s
  end
  
  def memcache_cache_key_of_belongs(method_name)
    clazz, id = clazz_id_of_belongs(method_name)
    clazz.memcache_key(id)
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
    ret = Object.const_get(clazz_name).memcache_load(id)
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
