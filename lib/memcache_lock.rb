class MemcacheLock
  
  # lock_expiry：锁设置成功后的过期时间。防止进程crash等导致忘记释放锁。
  # retries：当锁获取被阻塞时，重试的次数
  # sleep_base：当锁获取被阻塞时，首次sleep等待的时间
  def initialize(lock_expiry=30, retries=3, sleep_base=0.5)
    @lock_expiry = lock_expiry
    @retries = retries
    @sleep_base = sleep_base
  end
  
  def synchronize(key)
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
      return true if flag
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