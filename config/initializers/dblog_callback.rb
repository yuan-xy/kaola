class ActiveRecord::Base
  
  after_create :after_create_cb
  after_update :after_update_cb
  after_destroy :after_destroy_cb
  
  #around_update :around_update_cb
  #around_destroy :around_destroy_cb
  
  def after_create_cb
    Rails.logger.warn "after_create_cb #{self}"
  end

  def after_update_cb
    byebug
    Rails.logger.warn "after_update_cb #{self}"
  end
  
  def after_destroy_cb
    byebug
    Rails.logger.warn "after_destroy_cb #{self}"
  end
  
  
  def around_update_cb
    Rails.logger.warn 'in around update'
    yield
    Rails.logger.warn 'out around update'
  end
  
  def around_destroy_cb
    Rails.logger.warn 'in around destroy'
    yield
    Rails.logger.warn 'out around destroy'
  end
     
end
