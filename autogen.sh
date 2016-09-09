#bundle exec spring binstub --all
touch public/belongs.yaml
touch public/many.yaml
cp lib/templates/jbuilder/*.jbuilder ~/.rvm/gems/ruby-2.3.0/gems/jbuilder-2.4.1/lib/generators/rails/templates/
spring_pid=`ps -ef | grep "spring server" | grep -v grep | awk '{print $2}'`
if 	[ -n "$spring_pid" ]; then  
	kill -9 $spring_pid
fi
bundle install
rails r autogen.rb 
rails r gen_index.rb
