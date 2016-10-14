class ActiveRecord::Base
  
  after_commit :clear_cache, on: [:destroy, :update]
 
  def clear_cache
    Rails.logger.warn "after commit #{self}"
  end
   
end
