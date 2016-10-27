# 一种强约定风格的REST接口设计（与自动化实现）

这次的分享是今年做的一个项目的总结。

## 1. 缘起

我们在2016年初上线了一个网上药房：老白网laobai.com。半年多的时间，老白网的官网销售额在全国自营的网上药房里已经排名前5了。电商的后端需要有一套供应链管理系统，但是由于药品的特殊性，药品采购／仓储／物流等需要符合GSP规范，导致我们目前外购并同时使用两套供应链系统，一套通用版满足基本的功能需求，一套主要是药品的GSP审核的需要，两个系统之间还需要数据交换。此外，这些外购的系统也无法满足我们自己的一些定制化开发的需求。所以就迫切需要自己开发一个满足GSP规范的药品行业供应链系统。

外购的第三方的供应链系统有1000多张表，功能上的复杂度主要在数据表多且有关联，对性能／并发上到是没有太多的要求。当时的团队情况是有一个靠谱的DBA，有几个前端开发，但是缺少后端程序员。功能很多，需要开发的人力缺口很大，正是在这种情况下催生了本文提到的技术方案。方案的主要考虑是：
1. 数据库设计完成后，前端要求可以直接开始开发，不能等后端接口。
2. 后端的开发工作量要尽可能少，多用代码生成技术，因为没有专职的后端程序员。

因为可以参考第三方的数据库结构设计，也可以参考第三方的界面设计，所以数据库／前端都没有太多的不确定性。
 

## 2. REST的优点与不完备性

关于前后端之间的接口规范，主要有三种风格：RPC vs REST vs GraphQL。
RPC风格的接口规范是最传统的，但是不太合适基于Web的系统，所以本方案中不予考虑。
GraphQL调研了一下，它能够满足我们的第一个需求，前端可以定义接口，不依赖于后端。但是无法满足第二点，采用GraphQL的后端开发工作量很大，测试也麻烦，而且GraphQL太新，整个团队都没有使用的经验。
所以综合考虑还是采用REST规范。


REST规范在数据库类应用中使用广泛。针对数据库中的一张表，restful的api通过约定来定义好CRUD的全部接口api，不需要前后端之间沟通接口的设计，而且各种语言都有针对单表的CRUD后端自动代码生成，能够减少后端的开发工作量。约定大于配置是一个很好的软件工程实践，能够大大减少软件开发的复杂性。下面就是一个restful的api约定：

| 操作 | HTTP Method  | URI |
| :--------- | :-----| :---------- |
| 获取列表数据	|	GET	|     /表名(.:format)             |
| 添加新数据	|	POST	|    /表名(.:format)          | 
| 编辑新数据	|	GET	|     /表名/new(.:format)         |
| 编辑已有数据	|	GET	|     /表名/:id/edit(.:format)    |
| 查看已有数据	|	GET	|     /表名/:id(.:format)         |
| 修改已有数据	|	PUT	|     /表名/:id(.:format)         |
| 删除已有数据	|	DELETE	|  /表名/:id(.:format)        |


当然针对实际的软件开发需求，REST的规范还是太简单了。标准的Restful接口只有四个动作，CRUD。一个最常见的扩展（或者说是误用），就是使用更多的动作。因为常见的后端开发框架是controller+action的模式，一个controller对应一个资源，里面配置多个action对应前端用户的多个动作。典型的，比如一个帖子，点赞／取消赞是两个动作。然后随着业务的发展，还有锁帖／解锁操作，回复帖子／查看所有0回复帖子等等需要。于是就又了下面的这种url设计：

POST /topics/follow
POST /topics/unfollow
POST /topics/lock
POST /topics/unlock
POST /topics/reply
GET /topics/no_reply

慢慢的，接口越来越复杂，离原来的REST风格越来越远。当然，有人觉得这种风格也不错。DHH的观点是这种风格url需要改造为REST的风格，比如对于点赞的场景，可以认为有一个资源是topics/follows，然后这个资源有添加和删除两个操作。
关于DHH对这种风格的讨论，可参考下面的链接：
http://jeromedalbert.com/how-dhh-organizes-his-rails-controllers/

这里是中文翻译版：
http://mp.weixin.qq.com/s?__biz=MzAxNDEyMDI5NA==&mid=453464461&idx=1&sn=57341bf83cef600efb930a134f9ca636


这还只是对单表资源的CRUD操作，我们碰到的REST规范主要是缺失下面的一些部分：
1. 查询／分页／排序的支持。 REST接口只有一个列表的接口，对查询相关的功能没有约定。
2. 批量操作的支持。 REST接口默认只支持单个资源的操作，而实际的业务场景中经常需要有批量操作的需求，比如商品的批量上架、数据的批量删除等。
3. 有关联的数据表的支持。REST只支持单个资源的CRUD，而实际业务中经常有主子表的级联保存，关联表的查询等。

所以本方案主要考虑两点：
1. 扩展REST，针对上述三种场景约定好接口规范。 目的是让前端程序员只需要知道接口约定，就可以针对所有的数据库表进行接口开发。
2. 如何通过自动代码生成的方式实现这些规范，以减少后端开发的工作量。



## 3. REST扩展：单表批量操作（添加／更新／删除）

#### 批量删除接口
批量删除接口的url地址和删除接口一样，只是id的格式不一样。批量删除接口，一次传入多个id，id之间以英文逗号“,”分割。比如

	curl  -X DELETE http://scm.laobai.com:9291/tjb_roles/1234,5678.json

表示删除id为1234和5678的两条记录。


#### 批量新增接口

批量新增接口的url地址和新增接口一样，只是提交的数据格式不一样。
批量新增的话，提交的里层数据是一个数组

	{
	    "表名复数": [{id:id1, field:value,...},{id:id2}...]
	}

单个新增的话，提交的是一个hash对象

	{
	    "表名单数": {id:id, field:value,...}
	}


#### 批量修改接口

批量修改接口的url地址是“/表名/batch_update.json”，提交的数据是一个嵌套的多层hash, 内部结构以id的值为field的hash，如：

	{
	    "表名复数": {
		   id1 : { field:value,... },
		   id2 : { field:value },		   
		}
	}

作为对比，单个修改的话，提交的是一个hash对象

	{
	    "表名单数": {id:id, field:value,...}
	}



## 4. REST扩展：单表查询
单表的查询，uri直接重用rest规范，但是要约定好查询的参数的传递规范。我们定义了下面这些查询的请求格式

	s[field]=value
	s[like[field]]=value
	s[date[field]]=value
	s[range[field]]=value
	s[in[field]]=value

分别代表精确查询／like字符串模糊查询／date日期范围查询／range范围查询／in枚举查询。
如果有多个查询条件，条件之间是逻辑与的关系。

	s[field1]=value1&s[like[field2]]=value2

查询的field直接对应到数据库的字段。如果field有逗号“,”，则表示同时查询多个字段，其中一个满足条件即可，也就是OR查询。

	"/warehouses.json?s[like[delivery_company,address]]=测试"

这个查询的意思是查找所有delivery_company包含‘测试’或者address包含‘测试’的所有仓库。

针对like查询，value支持两种特殊字符“%”和“_”，其中“%”表示匹配任意多个字符，“_”匹配任意一个字符。
针对date/range/in查询，支持value中包含逗号“,”。

#### Like查询
	"/warehouses.json?s[like[fax]]=f%25"

#### 日期查询
	"/warehouses.json?s[date[created_at]]=2016-05-11"
	"/warehouses.json?s[date[created_at]]=2016-05-11,2016-05-12"

#### 数值范围查询
	"/warehouses.json?s[range[id]]=1,5"
	"/warehouses.json?s[range[id]]=,5"
	"/warehouses.json?s[range[id]]=3,"

#### 枚举In查询
	"/warehouses.json?s[in[id]]=1,2,5"

### 分页/排序

	curl "http://scm.laobai.com:9291/warehouses.json?page=1"
	curl "http://scm.laobai.com:9291/warehouses.json?page=1&per=100"
	curl "http://scm.laobai.com:9291/warehouses.json?page=1&order=id+desc"

分页参数page支持负数，-1代表最后一页，也就是采用逆序以后的第一页。比如：

	curl "http://scm.laobai.com:9291/warehouses.json?page=-1&order=created_at+asc"
	
排序order参数支持多个排序条件，以“,”号分隔，比如:

	curl "http://scm.laobai.com:9291/warehouses.json?page=1&order=warehouse_name+desc,warehouse_category+asc"





## 5. REST扩展：关联表的级联保存
## 6. REST扩展：关联表查询

存在的问题：没有对返回值进行约定。

## 7. 实现

