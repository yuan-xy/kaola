#!/bin/bash
# 上面这行强制使用bash，这样当本脚本在login/cron/god等各种环境下执行时sh都是bash。
# 下面这行保证在cron/god下执行puma的时候，也能和login shell一样设置一样的环境变量。
source /ebaolife/.bash_profile
bundle exec puma -d  -C /ebaolife/ScmApi/puma.rb
