class ActiveRecord::Base
  
  after_commit :clear_cache, on: [:destroy, :update]
 
  def clear_cache
    Rails.logger.warn "after commit #{self}"
  end
  
  def request_cache_of_belongs_to(method_name)
    id = self.send(method_name+"_id")
    key = get_belongs_class(method_name)+id.to_s
    return RequestStore.store[key] if RequestStore.store.has_key? key
    ret = self.send(method_name)
    RequestStore.store[key] = ret
    ret
  end
  
  def get_belongs_class(method_name)
    hash = $belongs_class[self.class.name.underscore]
    clazz = hash[method_name+"_id"]
    return clazz if clazz
    method_name.camelize
  end
   
end
