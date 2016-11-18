# Api接口自动生成系统使用

## 命名约定

这套系统能够运行的关键是命名约定。

### URL命名约定
本系统生成的Api接口是基于http的web接口，URL的命名符合REST规范。其中的表名都是复数形式。

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

| 批量添加数据	|	POST	|    /表名(.:format)          | 
| 批量修改数据	|	POST	|    /表名/batch_update(.:format)    | 
| 批量删除数据	|	DELETE	|  /表名/:id[,:id](.:format)          |

format目前支持两种：一个是json，这个是提供给前端使用的api接口；一个是空，也就是不带format，这个是后台提供的html显示界面。

### 数据库命名约定

* 表名用复数（注意特殊的英文复数规则）。如果要使用多个数据库，不同的数据库不要有同名的表
* 主键的名字都是”id“
* 外键的名字都是“表名单数_id”，如果一张表里有多个关联到另外一张表的外键，命名规则是“前缀_表名单数_id”
* 每张表可以添加默认的创建时间／修改时间字段， 字段名称必须是"created_at" "updated_at"，类型是datetime
* 字段的名字除了字母／数字／下划线，不能包含"."或者其它特殊字符
* 给数据库的表和字段添加注释，主要是表和字段的名字。如果要添加其它内容，在名字后加空格。比如有一个字段op_type，其注释是“类型	1-亿保健康，2-签约商家，3-商铺，4-保险公司，5-投保单位，6-保单分组”。那么字段名称就是“类型”，后面是字段的详细说明。


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
	

#### 批量删除接口
批量删除接口的url地址和删除接口一样，只是id的格式不一样。批量删除接口，一次传入多个id，id之间以英文逗号“,”分割。比如

	curl  -X DELETE http://scm.laobai.com:9291/tjb_roles/1234,5678.json

表示删除id为1234和5678的两条记录。如果删除成功，返回值格式：

		{id:[被删除的id], deleted:true}


#### 批量新增接口

批量新增接口的url地址和新增接口一样，只是提交的数据格式不一样。
批量新增的话，提交的里层数据是一个数组

	{
	    "表名复数": [{id:id, key:value,...},{}...]
	}

单个新增的话，提交的是一个hash对象

	{
	    "表名单数": {id:id, key:value,...}
	}

单个新增的话，有数据的验证，批量新增接口的是否对字段进行验证未知。

#### 批量修改接口

批量修改接口的url地址是“/表名/batch_update.json”，提交的数据是一个嵌套的多层hash, 内部结构以id的值为key的hash，如：

	{
	    "表名复数": {
		   id1 : { key:value,... },
		   id2 : { key:value },		   
		}
	}

作为对比，单个修改的话，提交的是一个hash对象

	{
	    "表名单数": {id:id, key:value,...}
	}

参考的输入例子：
	
	{
	    "ttr_request_headers": {
	        "0909d36d-15db-4cd1-b9b7-e084afd45d18": {
	            "approve_state": "0",
	            "audit_state": "0",
	            "close_reason": "close"
	        },
	        "0f4810f6-1c8f-47d8-9b4b-a1a6a8b7757a": {
	            "approve_state": "0",
	            "audit_state": "0"
	        }
	    }
	}


### 搜索相关功能
Rails的scaffold自动生成的代码只有基本的CRUD功能，没有提供查询功能，所以这里的搜索功能是我自定义的一套查询语法，包含查询／分页／排序功能，且所有的功能可自由组合。目前支持的查询条件类型包括：

	s[key]=value
	s[like[key]]=value
	s[date[key]]=value
	s[range[key]]=value
	s[in[key]]=value

key可以包含三种类型：单个key;多字段的key，格式："key1,key2,...";主子表的key，格式：“key1.key2”。其中，多字段的key的格式表示多个字段的or查询，只支持等于和like查询。


如果有多个查询条件，条件之间是逻辑与的关系。

	s[key]=value&s[like[key]]=value

### 列表接口

	curl http://scm.laobai.com:9291/tbw_warehouses.json


### 分页/排序

	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1"
	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1&per=100"
	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1&order=id+desc"

分页参数page支持负数，-1代表最后一页，也就是采用逆序以后的第一页。比如：

	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=-1&order=created_at+asc"
	
排序order参数支持多个排序条件，以“,”号分隔，比如:

	curl "http://scm.laobai.com:9291/tbw_warehouses.json?page=1&order=warehouse_name+desc,warehouse_category+asc"


### 查询
#### 等于查询

	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[fax]=fax"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[fax]=fax&page=1&order=id+desc"

#### Like查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[fax]]=f%25"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[fax]]=f%25&s[fax]=fax&s[old_supplier_id]=abcd"

Like查询的值支持两种特殊字符“%”和“_”，其中“%”表示匹配任意多个字符，“_”匹配任意一个字符。如果Like查询的值不包含特殊字符，则默认前后加上“%”。大部分情况下，查询时不需要加％这样的特殊字符，因为默认查询字符串前后都会加上“%”。除了一种情况：需要占位查询，比如以给定字符串开头或者结尾的查询。

#### 日期查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[created_at]]=2016-05-11"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[date[created_at]]=2016-05-11,2016-05-12"

#### 数值范围查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=1,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=,5"
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[range[id]]=3,"

#### 枚举In查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[in[id]]=1,2,5"

#### 多字段OR查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[delivery_company,address]]=测试"
	
这个查询的意思是查找所有delivery_company包含‘测试’或者address包含‘测试’的所有仓库。

多个查询条件仍然是AND的关系，比如下面的查询
	curl -g "http://scm.laobai.com:9291/tbw_warehouses.json?s[like[delivery_company,address]]=测试&s[warehouse_code]=11111"

其含义是查找（所有delivery_company包含‘测试’或者address包含‘测试’的仓库）并且 (warehouse_code等于11111)的所有仓库。

## 关联表功能的使用

### 关联表查看
支持在查看一条数据时，自动带出关联的belongs_to的父表的数据。

要自动带出所有的关联子表的数据（仅支持在开发环境下使用），传递“many=1”参数

	http://scm.laobai.com:9291/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=1

带出给定的几个关联子表数据：传递参数many=表1[,表2]

	http://118.178.17.98:3000/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=tso_saleorder_details
	http://scm.laobai.com:9291/tbw_warehouses/23dd811b-cd07-4f80-b7e2-62674f400c8e.json?many=tbe_express_print_templates,tbp_curing_headers

### 关联表的列表查看
带出给定的几个关联子表数据：传递参数many=表1[,表2]

	http://scm.laobai.com:9291/tbw_warehouses.json?many=tbe_express_print_templates,tbp_curing_headers

列表和浏览接口里的many关系数据自动带出功能，最多只返回100条数据，所以只支持many集合数据量较少的情况。如果数据量大，且需要排序／分页等需求，需要单独再调用一次查询接口。

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
	
### 关联表删除
关联表之间如果存在数据库外键约束，单独删除主表的数据是不能成功的。此时就需要把依赖于该主表的所有子表数据也删除。在删除的接口增加一个many参数，用于处理这种情况，传递格式“many=表1[,表2]”，比如：
	
	curl  -X DELETE http://scm.laobai.com:9291/tjb_roles/1234.json?many=tjb_operator_roles

关联表删除和批量删除是一个接口, 可以一次性删除。比如： /1,2,3,4.json?many=table1s,table2s
代表批量删除“1,2,3,4”四个数据，其中每个数据都级联删除两个子表“table1s,table2s”的所有关联数据。


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


### 查询的Count支持
上面提到的所有列表／查询／分页／关联表查询json接口，都支持查询的同时返回符合记录的条数总数。方式是在url中增加count=1的参数：

	curl http://scm.laobai.com:9291/tbw_warehouses.json?count=1

带count的json输出的格式：

	{
		"count":数字
		"data":[{字段名:值}]
	}

如果是不带count的搜索页输出，格式为：

	[{字段名:值}]

## 其它接口

### 直接数据库sql查询

首先ts_sql_infos，定义要查询的sql语句以及动态参数的类型，其中的动态参数传入部分用"?"表示，类型包括s/i/f/d，分别代表字符串／整数／浮点数／日期。多个参数类型，以英文逗号","分割。

查询的url是"/search/:id.json", 参数通过"1=...&2=..."来传递。暂不支持可选参数。

	curl http://localhost:3000/sql/search/3.json?1=5672c997783d1024b4bffa4c&2=%25%25&3=%25YD%25
	

### 数据库存储过程执行
待完善：

	curl http://localhost:3000/sql/exec/
	
### 健康检测接口

	curl http://localhost:3000/sql/heartbeat.json
	
## 相关文档

* [内部实现原理](http://git.ebaolife.net/SCM/ScmApiServer/blob/master/Tech.md)；

