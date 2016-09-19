match ':controller(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
get 'sql/heartbeat', to: 'sql#heartbeat'
get 'sql/search/:id', to: 'sql#search'
get 'sql/exec/:id', to: 'sql#exec'
get 'oauth2/login', to: 'oauth2#login'
get 'oauth2/callback', to: 'oauth2#callback'
