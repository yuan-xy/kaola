class Rack::Attack

  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blacklisting and
  # whitelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 
  
  self.throttle('req/ip', :limit => 100, :period => 10.seconds) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  self.throttle('raw_sql/ip', :limit => 1, :period => 3.seconds) do |req|
    if req.path.match /^\/sql\/search/
      req.ip
    else
      false
    end
  end
  
  def self.is_intranet(ip)
    if ip=="127.0.0.1" || ip=="::1" || ip.match(/^172\./) || ip.match(/^192\./) || ip.match(/^10\./)
      return true
    else
      return false
    end
  end
    
  self.blocklist('block internet') do |req|
    # !is_intranet(req.ip)
    false
  end

  self.blocklisted_response = lambda do |env|
    [ 503, {}, ['{"error":"Blocked"}']]
  end

  self.throttled_response = lambda do |env|
    [ 503, {}, ['{"error":"Retry later"}']]
  end

end