#match ':controller(/:action(/:id(.:format)))', via: [:options], to:  lambda {|env| [200, {'Content-Type' => 'text/plain'}, ["OK\n"]]}
#match ':controller/batch_update(.:format)', action: :batch_update, controller: :controller, via: [:post]
