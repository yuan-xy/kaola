# Api接口自动生成系统原理与使用

## 概览
该Api接口自动生成系统的输入是数据库连接（支持多个数据库连接），输出是一套ruby on rails代码。该代码运行后提供Api接口服务。接口采用REST规范，每一张表对应到一个REST的URI，提供增删改查的功能，且支持复杂查询和表关联。采用这套系统后，DBA负责设计好数据库，然后前端就可以直接针对Api接口进行开发了，采用前后端分离的开发模式。

注意：这套接口不能直接在外网开放，只能内部调用。

## 命名约定

这套系统能够运行的关键是命名约定。

### 数据库命名约定

* 表名用复数（注意特殊的英文复数规则）。如果要使用多个数据库，不同的数据库不要有同名的表
* 主键的名字都是”id“
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
对于以“_id”结尾的字段名，如果上一步没有匹配到表名，那么近一步去掉以“_”分割的前缀，把剩下的中间部分去匹配表名。去前缀匹配用于支持一张表有多个外键指向另一张表，只是前缀不同，比如仓库系统中的移库表中有两个仓库id，分别是from_tbw_warehouse_id／to_tbw_warehouse_id，所以必须有前缀加以区分。如果找到了，就建立两个表的单向关联关系，也就是只建立
Table1 belongs_to table2
不建立
Table2 has_many  table1s


#### 3.更新模型层
根据上面扫描得到的表关联信息，更新Ruby代码的模型层，增加belongs_to和has_many的申明，这样就可以支持在ruby层通过table1.table2、table2.table1s这样的对象访问的方式遍历关系层次。

#### 4.序列化关系数据，并在运行时读取
上面扫描得到的两个关系：belongs_to和has_many，组织成两个hash表，key是表名，value是对应关系的表名的数组，然后把这两个hash对象序列化成YAML文件，文件名分别是belongs.yaml和many.yaml。Rails程序启动时，会读取这两个文件，然后重新反序列化得到belongs_to和has_many的两个hash表。


## 使用说明
这里所有的使用说明都是以“http://scm.laobai.com:9291”网址的运行中系统为例子。
###元数据查询
查看所有的表

	http://scm.laobai.com:9291/index2.html
	
查看所有的belongs_to(隶属)关系

	http://scm.laobai.com:9291/belongs.yaml
	
查看所有的many(包含)关系

	http://scm.laobai.com:9291/many.yaml

### CRUD功能

标准REST接口, 支持两种调用方式: 网页调用和json调用，对应的Content-Type的值分别为 application/x-www-form-urlencoded, application/json。如果json接口调用出错，那么返回的json中包含error字段提供错误的说明信息。


#### 新增接口
模拟x-www-form-urlencoded编码调用：

	curl  -d "tjb_role[id]=1234&tjb_role[role_name]=name" http://scm.laobai.com:9291/tjb_roles.json

模拟json编码调用：

	curl -X POST --header "Content-Type: application/json" -d @roles.json http://scm.laobai.com:9291/tjb_roles.json

#### 读取接口

	curl http://scm.laobai.com:9291/tjb_roles/1234.json

#### 修改接口

	curl  -X PUT -d "tjb_role[role_name]=name2" http://scm.laobai.com:9291/tjb_roles/1234.json


#### 删除接口

	curl  -X DELETE http://scm.laobai.com:9291/tjb_roles/1234.json
	
很多浏览器不支持出了GET／POST以外的其它方法，那么可以通过下面的方式调用
	
	curl  -X POST -d "_method=delete" http://scm.laobai.com:9291/tjb_roles/1234.json
	

### 搜索相关功能
Rails的scaffold自动生成的代码只有基本的CRUD功能，没有提供查询功能，所以这里的搜索功能是我自定义的一套查询语法，包含查询／分页／排序功能，且所有的功能可自由组合。多个查询条件之间是逻辑与的关系。

s[key]=value
s[like[key]]=value
s[date[key]]=value
s[range[key]]=value
s[in[key]]=value

s[key]=value&s[like[key]]=value

### 列表接口

	curl http://scm.laobai.com:9291/tbw_warehouses.json


### 分页/排序

	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1"
	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1&per=100"
	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1&order=id+desc"

### 查询
#### 等于查询

	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[fax]=fax"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[fax]=fax&page=1&order=id+desc"

#### Like查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[fax]]=f%25"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[fax]]=f%25&s[fax]=fax&s[old_supplier_id]=abcd"


#### 日期查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[created_at]]=2016-05-11"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[created_at]]=2016-05-11,2016-05-12"

#### 数值范围查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=1,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=3,"

#### 枚举In查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[in[id]]=1,2,5"


## 关联表功能的使用

### 关联表查看
支持在查看一条数据时，自动带出关联的belongs_to的父表的数据。

要自动带出所有的关联子表的数据（仅支持在开发环境下使用），传递“many=1”参数

	http://scm.laobai.com:9291/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=1

带出给定的几个关联子表数据：传递参数many=表1[,表2]

	http://118.178.17.98:3000/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=tso_saleorder_details
	http://scm.laobai.com:9291/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=tbe_express_print_templates,tbp_curing_headers
### 关联表保存
支持在一个事务里保存主表和关联的多个子表。
在test/jsontest目录下有一个例子。

	{
		"tjb_role": {
			"id": "57",
			"owner_module": "test",
			"role_name": "测试角色",
			"role_desc": "HELLO1",
			"state": 0,
			"updated_tjb_operator_id": "048e7eb9-c533-40cc-ad39-738d24f0452d",
			"updated_operator_name": "测试"
		},
		"tjb_operator_roles": [{
			"id": "57",
			"tjb_operator_id": "f9f5ae4b-50d6-42e5-b46e-46b0b3a44c50",
			"state": 0,
			"updated_tjb_operator_id": "048e7eb9-c533-40cc-ad39-738d24f0452d",
			"updated_operator_name": "测试"
		}]
	}


	curl -X POST --header "Content-Type: application/json" -d @roles.json http://scm.laobai.com:9291/tjb_roles.json
	

### 关联表查询
关联表的查询支持所有单表查询的功能，包括等于／Like／日期／数值范围／枚举查询。
#### 等于查询

	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[tbc_company.company_name]=测试公司"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[tbc_company.company_name]=测试公司&page=1&order=id+desc"

#### Like查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[tbc_company.company_name]=测试%25"

#### 日期查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[tbc_company.created_at]]=2016-05-11"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[tbc_company.created_at]]=2016-05-11,2016-05-12"

#### 数值范围查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[tbc_company.id]]=1,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[tbc_company.id]]=,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[tbc_company.id]]=3,"

#### 枚举In查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[in[id]]=1,2,5"



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

	git branch a_new_branch		建立一个分支a_new_branch
	git checkout a_new_branch		切换到该分支
	
安装项目依赖的第三方库，运行

	bundle

### 2. 配置数据库连接

数据库配置文件是config目录下的database.yaml，在这个文件里配置数据库连接。默认的三个数据库连接是development／test／production，分别代表开发／测试／发布环境下的默认数据库连接。如果一个环境下要连多个数据库，按照类似的命名规则加前缀即可。比如user_development/user_test/user_production等。

### 3. 自动生成代码

在项目的根目录运行

	./autogen.sh

### 4. 启动停止服务

启动服务，在项目的根目录运行

	./start.sh

停止服务

	./stop.sh

重启服务

	./restart.sh

