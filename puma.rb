#!/usr/bin/env puma

directory '/ebaolife/ScmApi'
environment 'development'

daemonize true

pidfile '/ebaolife/ScmApi/log/puma.pid'

state_path '/ebaolife/ScmApi/log/puma.state'

bind 'tcp://0.0.0.0:9291'

bind 'unix:///ebaolife/ScmApi/log/puma.sock'

on_restart do
  puts 'On restart...'
end
