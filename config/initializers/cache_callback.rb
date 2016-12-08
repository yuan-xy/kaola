class ActiveRecord::Base
  
  after_commit :clear_cache, on: [:destroy, :update]
 
  def clear_cache
    Rails.logger.warn "after commit #{self}"
  end
  
  def request_cache_of_belongs_to(method_name)
    id = self.send(method_name+"_id")
    cache = RequestStore.store[method_name+id.to_s]
    return cache if cache
    ret = self.send(method_name)
    RequestStore.store[method_name+id.to_s] = ret
    ret
  end
   
end
