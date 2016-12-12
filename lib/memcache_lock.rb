class MemcacheLock
  
  def initialize(lock_expiry=10, retries=3, sleep_base=0.5)
    @lock_expiry = lock_expiry
    @retries = retries
    @sleep_base = sleep_base
  end
  
  def synchronize(key)
    raise 'already synchronized with this lock' if @random
    @random = SecureRandom.uuid
    acquire_lock(key)
    begin
      yield
    ensure
      release_lock(key)
    end
  end
  
  def acquire_lock(key)
    @retries.times do |count|
      flag = Rails.cache.dalli.add(key, Process.pid, @lock_expiry)
      return if flag
      exponential_sleep(count)
    end
    raise "Couldn't acquire memcache lock for: #{key}"
  end
  
  def release_lock(key)
    Rails.cache.dalli.delete(key)
  end
  
  def exponential_sleep(count)
    sleep(@sleep_base*(2**count))
  end
  

end