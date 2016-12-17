cp lib/templates/jbuilder/*.jbuilder ~/.rvm/gems/ruby-2.3.0/gems/jbuilder-2.4.1/lib/generators/rails/templates/
spring_pid=`ps -ef | grep "spring server" | grep -v grep | awk '{print $2}'`
if 	[ -n "$spring_pid" ]; then  
	kill -9 $spring_pid
fi

if [ "$1" = '-v' ] ; then
	rails r incremental_update.rb verbose $2
else
	rails r incremental_update.rb $1
fi

rails r gen_index.rb
