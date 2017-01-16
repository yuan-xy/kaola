# Api接口自动生成系统原理

## 概览
该Api接口自动生成系统的输入是数据库连接（支持多个数据库连接），输出是一套ruby on rails代码。该代码运行后提供Api接口服务。接口采用REST规范，每一张表对应到一个REST的URI，提供增删改查的功能，且支持复杂查询和表关联。采用这套系统后，DBA负责设计好数据库，然后前端就可以直接针对Api接口进行开发了，采用前后端分离的开发模式。

注意：这套接口不能直接在外网开放，只能内部调用。

## 命名约定

这套系统能够运行的关键是命名约定。

### 数据库命名约定

* 表名用复数（注意特殊的英文复数规则）。如果要使用多个数据库，不同的数据库不要有同名的表
* 主键的名字都是”id“。如果要使用批量删除接口，id的值不能包含逗号“,”
* 外键的名字都是“表名单数_id”，如果一张表里有多个关联到另外一张表的外键，命名规则是“前缀_表名单数_id”
* 每张表可以添加默认的创建时间／修改时间字段， 字段名称必须是"created_at" "updated_at"，类型是datetime
* 字段的名字除了字母／数字／下划线，不能包含"."或者其它特殊字符
* 给数据库的表和字段添加注释，主要是表和字段的名字。如果要添加其它内容，在名字后加空格。比如有一个字段op_type，其注释是“类型	1-亿保健康，2-签约商家，3-商铺，4-保险公司，5-投保单位，6-保单分组”。那么字段名称就是“类型”，后面是字段的详细说明。

### URL命名约定
本系统生成的Api接口是基于http的web接口，URL的命名符合REST规范。

| 操作 | HTTP Method  | URI |
| :--------- | :-----| :---------- |
| 获取列表数据	|	GET	|     /表名(.:format)             |
| 添加新数据	|	POST	|    /表名(.:format)          | 
| 编辑新数据	|	GET	|     /表名/new(.:format)         |
| 编辑已有数据	|	GET	|     /表名/:id/edit(.:format)    |
| 查看已有数据	|	GET	|     /表名/:id(.:format)         |
| 修改已有数据	|	PATCH	|   /表名/:id(.:format)       |
| 修改已有数据	|	PUT	|     /表名/:id(.:format)         |
| 删除已有数据	|	DELETE	|  /表名/:id(.:format)        |

format目前支持两种：一个是json，这个是提供给前端使用的api接口；一个是空，也就是不带format，这个是后台提供的html显示界面。

## 代码生成过程
### 第一步，获取数据库的表信息
获取所有的表名

    ActiveRecord::Base.connection.tables

获取表的字段名

    ActiveRecord::Base.connection.columns("tbw_warehouses")
    ActiveRecord::Base.connection.columns("tbw_warehouses").map{|x| x.name}
    ActiveRecord::Base.connection.columns("tbw_warehouses").map{|x| x.sql_type}

获取表的注释信息

    TbcImg.connection.retrieve_table_comment("tbw_warehouses")
    TbcImg.connection.retrieve_column_comments("tbw_warehouses")

### 第二步，针对每张表生成CRUD功能代码
根据数据库表名和字段名，生成shell代码，该代码利用rails框架自带的scaffold功能，自动生成单表的带CRUD（创建／读取／更新／删除）功能的接口和页面代码。比如：

    rails g scaffold TbcImg id:string img_type:integer img_title:string img_desc:string img_url:string updated_tjb_operator_id:string updated_operator_name:string -f

### 第三步，通过外键的命名规则扫描所有数据库，建立表关联
#### 1.全匹配

对每一张表，查看所有以“_id”结尾的字段名，把该字段的去掉“_id”的前缀匹配表名，如果找到了，就建立两个表的关联关系。匹配表名的时候是不区分数据库的，所以表关联支持跨数据库的关联。当然，这样要求不同的数据库不能有同名的表。

关联关系是双向的，对于两个表table1s和table2s，如果table1s有一个字段table2_id，那么：
Table1 belongs_to table2
Table2 has_many  table1s

通常情况下，一个外键有三种可能： has_one, has_many, has_and_belongs_to_many，也就是常说的一对一，一对多，多对多。为了简化代码，这里统一采用has_many关系。

#### 2.去前缀后匹配
对于以“_id”结尾的字段名，如果上一步没有匹配到表名，那么进一步去掉以“_”分割的前缀，把剩下的中间部分去匹配表名。去前缀匹配用于支持一张表有多个外键指向另一张表，只是前缀不同，比如仓库系统中的移库表中有两个仓库id，分别是from_tbw_warehouse_id／to_tbw_warehouse_id，所以必须有前缀加以区分。如果找到了，就建立两个表的单向关联关系，也就是只建立
Table1 belongs_to table2
不建立
Table2 has_many  table1s


#### 3.更新模型层
根据上面扫描得到的表关联信息，更新Ruby代码的模型层，增加belongs_to和has_many的申明，这样就可以支持在ruby层通过table1.table2、table2.table1s这样的对象访问的方式遍历关系层次。

#### 4.序列化关系数据，并在运行时读取
上面扫描得到的两个关系：belongs_to和has_many，组织成两个hash表，key是表名，value是对应关系的表名的数组，然后把这两个hash对象序列化成YAML文件，文件名分别是belongs.yaml和many.yaml。Rails程序启动时，会读取这两个文件，然后重新反序列化得到belongs_to和has_many的两个hash表。


## 缓存系统的说明

整个缓存系统分为两大类：单个对象缓存，many关系的列表缓存。其中，单个对象缓存过期是精确删除该缓存；而列表缓存则不主动清除，采用被动清除策略。

### 单个对象缓存
#### 缓存Key的设计

单个对象的缓存的key设计如下：

    "#{prefix}:#{name}:#{id}"

其中，prefix是整张表的一个全局编号。主要用于批量过期一张表的所有相关缓存数据。name是该对象的名字，对应到一张表。id是该对象的主键。

#### 缓存的使用
根据id加载对象有三种方式，第一种是通过数据库查询加载：

	Class.find(id)
	
另一种是通过Memcache缓存加载，如果缓存没有则通过数据库查询加载：
	
	Class.memcache_load(id)
	
还有一种缓存是利用ThreadLocal存储实现的单次Web请求的本机内存缓存，加载方式是：
 
	Class.request_cache_load(id)

#### 外键对象的缓存

单个对象的本机内存缓存，一般称为IdentifyMap。通常所有的ORM框架，针对同一个对象的多次find请求，会利用到本机内存缓存。但是如果多个不同的对象，都指向同一个外键对象，这种情况下不一定会利用到本机内存缓存。而且ORM框架不知道应用场景，所以也没法做深入的优化。针对本系统的众多belongs_to外键对象，在一次web请求的过程中，会利用到本机内存缓存。调用方式如下：
 
	object.cache_of_belongs_to 'belongs_to_name'

其中object是主对象，belongs_to_name是外键字段的名字，返回的是加载好的外键对象。整个方法的执行分三步：1.首先查看本次请求的内存缓存中是否有外键对象；2.如果没用尝试从memcache加载；3.如果没有从数据库加载。

### 多个对象缓存

首先，针对列表页请求，目前没有进行缓存。主要的原因是列表页的数据太灵活，查询条件／分页／排序／总数都会影响到最终结果，不太适合用key-value式的缓存。而且目前所有的列表页请求都是单表查询，不做join，所以数据库执行的速度还可以。

所以本系统的多个对象缓存只有一种情况，就是一对多的many关系的缓存。many对象最多支持加载100条，所以缓存最多也是100条。

#### 缓存Key的设计
many关系的列表缓存的key设计如下：

    "#{prefix}#{table}_#{timestamp}:#{name}_#{id}"

其中，prefix是关联的many表的一个全局编号。主要用于批量过期一张表的所有相关缓存数据。table是关联表的名字。timestamp是内部维护的关联表的版本时间戳。name是主对象的名字，对应到一张表。id是主对象的主键。

比如一个部门Depart对象有很多个员工User对象，假设user表当前的prefix为2，timestamp为33，那么部门1的所有员工的缓存key为：

    "2users_33:Depart_1"

如果users表有增删改的变更，那么时间戳会加1，下次加载部门1的所有员工，其缓存的key就是

    "2users_34:Depart_1"

这样老的缓存数据就自动过期了。同理，如果有外部程序直接更改了数据库的users表，则需要将prefix加1，那么新的缓存的key就是

    "3users_34:Depart_1"

Timestamp字段的作用是应用内部记录一张表的修改时间戳，用于该表的集合类缓存的过期控制。该表的单个对象的缓存，通过主键id可以直接定位到，所以可以直接清除缓存（而不是过期）。而prefix用于外部程序修改数据库后，过期所有的集合类和单个对象类的缓存。采用变更key的方式过期缓存是不精确的，有可能不需要的过期的缓存也清除了。


| 数据库表 | 应用内部变更  | 外部程序变更 |
| :--------- | :-----| :---------- |
| 单个对象	|	删除key	|    过期key（变更prefix）  |
| 集合对象	|	过期key（变更timestamp）	|    过期key（变更prefix）           | 


#### 缓存的使用

	obj.many_cache(table)


### 缓存请求的合并
一个对象往往有多个外键对象，可以利用memcache的pipeline特性加速网络请求，调用方式如：

	objecct.belongs_to_multi_get

如果一组列表对象，而每个对象又要获取所有的外键对象，那么可以通过两种方式加速：1. 重复请求的合并，2. 多个请求的pipeline加速，调用方式如：

	Class.belongs_to_multi_get(list)


如果一组列表对象，每个对象要获取table指向的many关系对象，调用方式如：

	Class.many_caches(table, list)

其中list表示一组列表对象，其中的每个对象都要加载table的集合，而Class则是list对象的类对象。

## 新项目配置说明
本系统依赖于ruby on rails， 所以在配置新项目前要安装好ROR环境。

### 0. 安装Ruby On Rails环境

	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	ping -c 3 get.rvm.io
	curl -sSL https://get.rvm.io | bash -s stable --ruby
	source ~/.rvm/scripts/rvm
	ruby -v
	gem -v
	gem source --remove https://rubygems.org/
	gem source -a https://gems.ruby-china.org
	
### 1. Clone代码库

	git clone http://git.ebaolife.net/SCM/ScmApiServer.git
	
建立一个分支，并chekout到该分支

	git branch a_new_branch		#建立一个分支a_new_branch
	git checkout a_new_branch		#切换到该分支
	git update-index --assume-unchanged config/routes.rb   #忽略对路由文件的本地修改
	
安装项目依赖的第三方库，运行

	bundle
	
忽略后续对config/routes.rb文件的修改

	git update-index --assume-unchanged config/routes.rb
	
### 2. 配置数据库/缓存

数据库配置文件是config目录下的database.yaml，在这个文件里配置数据库连接。默认的三个数据库连接是development／test／production，分别代表开发／测试／发布环境下的默认数据库连接。如果一个环境下要连多个数据库，按照类似的命名规则加前缀即可。比如user_development/user_test/user_production等。

默认情况下，在开发环境使用的是本地文件缓存；在发布环境下使用的是memcache。Memcache的服务器地址要设置在环境变量“MEMCACHE_SERVERS”中。

发布环境下还需要配置环境变量“rb_servers”，表示部署了本api接口的所有ruby服务器的ip地址，多个IP地址以逗号分隔，比如rb_servers="10.24.153.87,10.26.111.209"。通常ruby服务器不是监听在80端口，这时还需要带上端口号，如rb_servers="10.24.153.87:3000,10.26.111.209:3000"。

### 3. 自动生成代码

对一个新的项目，要根据数据库生成所有的代码，在项目的根目录运行：

	./autogen.sh [-v]

	
可选参数“-v”控制输出详细日志信息。如果项目的代码已经生成，而有少量表新增，那么可以增量更新

	./incremental_update.sh [-v]

增量更新时，只处理新增的表，已有的表的字段变更不会处理。不过增量更新时仍然会全部重新计算一次表关联。

如果只对少量新增的表生成CRUD代码，而不重新计算表关联，那么可以增加参数no_relation来执行：

	./incremental_update.sh no_relation

如果只是想重新计算表关联，那么可以执行：

	rails r gen_relations.rb
	
### 4. 启动停止服务

启动服务，在项目的根目录运行

	./start.sh

停止服务

	./stop.sh

重启服务

	./restart.sh

##多项目的支持

如果有多个项目都需要这套自动生成的后端API，那么可以为每一个项目建立一个独立的分支。通用功能的开发在master分支，每个项目特定的配置保存在自己的分支。

	git branch 					#查看当前有哪些分支

	git branch a_new_branch		#建立一个分支a_new_branch

如果master有功能更新，那么需要把主分支的功能合并到当前分支
	
	git merge origin master				#合并主分支的代码
	git push origin a_new_branch	#合并后的代码提交的当前分支
	
发布脚本里对部署路径有依赖，比如新的分支名字是“a_new_branch”，那么执行下面的命令更新部署相关配置：

	rpl ScmApiServer a_new_branch puma.rb 
	find . -name "*.sh" | xargs rpl ScmApiServer a_new_branch

