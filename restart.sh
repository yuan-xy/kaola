#!/bin/bash
source /ebaolife/.bash_profile
bundle exec rake assets:precompile
bundle exec pumactl -P /ebaolife/ScmApi/log/puma.pid phased-restart
