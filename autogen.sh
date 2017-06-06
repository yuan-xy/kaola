#bundle exec spring binstub --all
touch public/belongs.yaml
touch public/belongs_class.yaml
touch public/many.yaml
spring_pid=`ps -ef | grep "spring server" | grep -v grep | awk '{print $2}'`
if 	[ -n "$spring_pid" ]; then  
	kill -9 $spring_pid
fi


if [ "$1" = '-v' ] ; then
	bundle install
	rails r autogen.rb verbose $2
else
	bundle install --quiet
	rails r autogen.rb $1
fi

rails r gen_index.rb
