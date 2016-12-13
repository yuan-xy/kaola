class ActiveRecord::Base
  
  def self.prefix
    @@memcache_prefix ||= nil
    init_prefix unless @@memcache_prefix
    @@memcache_prefix
  end

  def self.inc_prefix
    init_prefix
    @@memcache_prefix += 1
    Rails.cache.write(prefix_key, @@memcache_prefix)
  end
  
  private
      
  def self.prefix_key
    "prefix:#{name}"
  end
  
  def self.init_prefix
    @@memcache_prefix = Rails.cache.read(prefix_key)
    unless @@memcache_prefix
      @@memcache_prefix = 1 
      Rails.cache.write(prefix_key, @@memcache_prefix)
    end
  end
   
end
