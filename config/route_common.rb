match ':controller(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
match ':controller/batch_update(.:format)', action: :batch_update, controller: :controller, via: [:post]

get 'sql/heartbeat', to: 'sql#heartbeat'
get 'sql/search/:id', to: 'sql#search'
get 'sql/exec/:id', to: 'sql#exec'
get 'oauth2/login', to: 'oauth2#login'
get 'oauth2/callback', to: 'oauth2#callback'
post 'bulk', to: 'bulk#batch'