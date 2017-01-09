#!/usr/bin/env puma
directory '/usr/src/app'
environment 'production'
daemonize false
pidfile '/usr/src/app/log/puma.pid'
state_path '/usr/src/app/log/puma.state'
bind 'tcp://0.0.0.0:3000'
on_restart do
  puts 'On restart...'
end
