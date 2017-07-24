怎么把本地的git修改提交到github，其实很简单。

首先添加一个远端仓库github：
$ git remote add github https://github.com/yuanxinyu/kaola.git

然后把本地的kaola分支推送到github的master分支。
$ git push -u github kaola:master

