get 'sql/heartbeat', to: 'sql#heartbeat'
get 'sql/search/:id', to: 'sql#search'
get 'sql/exec/:id', to: 'sql#exec'
get 'oauth2/login', to: 'oauth2#login'
get 'oauth2/callback', to: 'oauth2#callback'
post 'bulk', to: 'bulk#batch'
post 'bulk/import', to: 'bulk#import'
get 'bulk/file_upload', to: 'bulk#file_upload'
get 'bulk/file_template', to: 'bulk#file_template'
post 'cache/expire', to: 'cache#expire'
post 'cache/expire_all', to: 'cache#expire_all'

match 'sql(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
match 'oauth2(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
match 'bulk(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
match 'cache(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
