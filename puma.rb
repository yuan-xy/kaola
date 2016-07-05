#!/usr/bin/env puma

directory '/ebaolife/ScmApiServer'
environment 'development'

daemonize true

pidfile '/ebaolife/ScmApiServer/log/puma.pid'

state_path '/ebaolife/ScmApiServer/log/puma.state'

bind 'tcp://0.0.0.0:9291'

bind 'unix:///ebaolife/ScmApiServer/log/puma.sock'

on_restart do
  puts 'On restart...'
end
