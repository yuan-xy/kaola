require 'byebug'

class Rack::Attack

  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blacklisting and
  # whitelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 
  
  self.throttle('req/ip', :limit => 20, :period => 10.seconds) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  self.throttle('raw_sql/ip', :limit => 1, :period => 3.seconds) do |req|
    if req.path.match /^\/sql\/search/
      req.ip
    else
      false
    end
  end


  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_response = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end

end