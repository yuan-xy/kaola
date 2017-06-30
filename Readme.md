# 一个超酷的Restful Api自动生成器：Kaola

## 0. 什么是Kaola

Kaola（考拉，英文koala）是一个全自动的restful api代码自动生成系统。给定一个数据库，只需要配置好数据库连接，koala可以通过扫描数据库自动生成全套的restful api的后端代码。通过预先约定好的接口调用规范，前端就可以直接开发应用系统了。



## 1. 为什么开发Kaola

类似koala的代码生成系统之前也有很多，比如rails自带的scaffold功能，以及更完善的Active Admin／Rails Admin等。但是这些系统都有两点不符合要求：
1. 这些系统都是一套完整的系统，从后端到页面都一次性生成。实际的情况是，后端的接口比较通用，而界面和操作流程往往需要深度的定制。修改这些系统自动生成的页面是很困难的。
2. 这些系统往往都是只支持单表CRUD操作，对多表之间的关联操作支持不够。

所以我开发了这套koala系统，它的主要特点是：
1. 只提供后端的restful api接口，前端的代码还是需要每个应用自己编写，采用前后端分离架构；
2. 接口不仅支持常规的单表CRUD操作，还自动支持多表关联（一对多、多对多、自引用的树形结构），支持复杂的查询（分页、排序、计数、索引）、支持批量操作、以及拥有一套透明高效的缓存体系。

当然，还有一点很重要的，就是定义了一套restful的基于约定的接口协议。基于这套约定的协议，前端程序员不需要后端提供繁琐的不一致接口文档，可以轻松上手开始使用这套接口。


## 2. 开始使用Kaola

Kaola是基于ruby on rails开发的，主要在Mac和Linux操作系统下完成开发
，数据库使用的是mysql。如果你的操作系统是windows，或者数据库不是mysql，大体上是兼容的，但可能会碰到问题。

1. 安装ruby2.2以上版本，如何安置可参考https://www.ruby-lang.org/en/documentation/installation/。安装完成ruby以后，在命令行运行”gem install bundle”以安装bundle；

2. 下载koala的代码，在项目根目录运行“bundle install”安装依赖的第三方库

3. 配置数据库连接，具体参考[数据库配置](doc/配置文件.md)；

4. 在项目的根目录运行“./autogen.sh”，自动生成所有的后端api代码

5. 启动api服务器，在开发环境下就是运行“rails server”


然后打开浏览器访问http://localhost:3000/index2.html就可以看到生成的所有接口了。在开发环境下，koala除了api接口，也提供完整的CRUD的html页面（其实就是rails默认的scaffold生成的页面）。在发布环境下，只有接口调用可以访问，基本就是以".json"结尾的url访问。

## 3. Kaola的接口协议约定
Kaola生成的Api接口是基于http的web接口，URL的命名基本沿用rails框架的命名约定，其中的表名都是复数形式。基本的CRUD接口的约定如下：

| 操作 | HTTP Method  | URI |
| :--------- | :-----| :---------- |
| 获取列表数据	|	GET	|     /表名(.:format)             |
| 添加新数据	|	POST	|    /表名(.:format)          | 
| 修改已有数据	|	PUT	|     /表名/:id(.:format)         |
| 查看已有数据	|	GET	|     /表名/:id(.:format)         |
| 删除已有数据	|	DELETE	|  /表名/:id(.:format)        |


这只是对单表资源的CRUD操作，koala针对下列情况也定义了一套的Restful规范：

1. 查询／分页／排序的支持。 标准Restful接口只有一个列表的接口，对查询相关的功能没有约定，koala自行扩展了一套约定。
2. 批量操作的支持。 Restful接口默认只支持单个资源的操作，而实际的业务场景中经常需要有批量操作的需求，比如商品的批量上架、数据的批量删除等。
3. 有关联的数据表的支持。Restful只支持单个资源的CRUD，而实际业务中经常有主子表的级联保存，关联表的查询等。

### 查询的约定
Kaola的查询参数一一对应到数据库中的字段，格式是通过把json格式的查询参数扁平化得来的。比如下面的查询条件，

	{
	    "s" : {
			gender : 'm',
			"like" : {
				name : 'b'
			}
		},
		"order" : "id asc"
	}
	
它的含义是查找所有gender等于'm'并且name包含'b'的记录，按'id asc'排序，扁平化以后就是：

	s[gender]=m&s[like[name]]=b&order=id asc

如果表的名字是‘users’，那么请求‘users.json?s[gender]=m&s[like[name]]=b&order=id+asc’就可以得到所有符合条件的json格式的数据。

针对查询／分页／排序／批量操作／关联表操作／导入导出等的具体的约定（前端开发者需要细看）可以参考：

* [kaola api协议规范](doc/Api.md)；

## 4. 实现原理

扫描数据库实现所有单表的CRUD功能接口，这个不难实现。比较难的是怎么处理数据关联关系。数据关联关系主要有三种：一对多，一对一，多对多。Kaola在实现关联关系的时候，分两个阶段实现的。

### 识别一对多关系

第一个阶段，在2016年项目最初开发的时候 ，只支持一对多关系。一对一关系是一对多关系的特例，而多对多关系则可以表示为两个一对多关系，所以只支持一对多关系也不算严重的缺陷。

那么如何自动发现数据库所有的一对多关系呢，主要通过三种方法：
1. 通过数据库的外键。如果A表有一个外键指向B表，那么B表和A表就是一对多关系。
2. 通过命名约定。外键的命名约定采用rails默认的约定，外键的名字都是“表名单数\_id”。同时有扩展，如果一张表里有多个关联到另外一张表的外键，命名规则是“前缀_表名单数\_id”。所有符合命名约定的表，即使没有设置数据库层的外键，也自动建立一对多关系。
3.通过配置文件。有些遗留的数据库即没有配置外键，也不符合命名约定，那么在配置文件custom_fk.txt文件中配置好外键关系也可以。


关联关系是双向的，对于两个表table1s和table2s，如果table1有一个字段table2\_id，那么table1是多方，table2是一方，用rails来描述就是：

	Table1 belongs_to table2
	Table2 has_many  table1s

### 识别多对多关系

第二个阶段是2017年，kaola开发完成接近一年的时候，有个项目组提出要多对多关系的支持，在压力下想明白了多对多关系。首先，rails支持两种多对多关系：直接式的“has_and_belongs_to_many”和间接式的“has_many through”

http://guides.rubyonrails.org/images/habtm.png

http://guides.rubyonrails.org/images/has_many_through.png

http://guides.rubyonrails.org/association_basics.html#choosing-between-has-many-through-and-has-and-belongs-to-many

Rails已经不建议使用直接式的多对多关系，Kaola也不支持这种方式。 下面就是自动发现多对多关联的最关键一步：所有包含两个及以上外键（也包括命名约定／配置文件定义的外键 ）的表自动形成多对多关系。一张表有2/3/4个外键，分别会定义1/2/6个多对多关系，也就是给定n个外键，生产组合C2n个多对多关系。

例子：

除了常规的三种关系，还有一种特殊的自引用关系：树形结构。树形结构最常见的例子有组织结构、产品类别等。为了存储树形结构，要求给定的表有一个指向自己的外键。外键值为空的节点是树的根节点。树形结构在kaola中被定义为一个指向自己的一对多关系。

### 关系的增删改查

识别了这些常见的数据关联关系后，接下来的任务是如何支持对这些关系的增删改查操作。由于kaola采用json格式提交数据，所以新增和修改有关系的数据是比较容易的，json格式很容易支持用嵌套结构来表达一对多关系。比如单个新增的话，提交的是一个hash对象

	{
	    "表名单数": {id:id, key:value,...}
	}
	
那么对于一次性提交主子表的数据，格式就是

	{
	    "主表单数": {id:id, key:value,...},
		"子表复数": [
		    {id:id, key:value,...},
			{id:id, key:value,...}
		],
		其它子表...
	}
	
下一步是如何定义和实现关联关系的查询。


#### Exists查询
主子表增加子表是否为空的exists查询。比如下面的查询表示查询所有的tbp_products，其在tbp_product_mappings表中不存在。主表是tbp_products，子表是tbp_product_mappings，且要求字表存在字段tbp_product_id。
	curl -g "http://scm.laobai.com:9291/tbp_products.json?s[exists[tbp_product_mappings]]=0"

查询的值只能是0或者1，分表代表子表集合为空或者非空。
	curl -g "http://scm.laobai.com:9291/tbp_products.json?s[exists[tbp_product_mappings]]=1&count=1"


#### 树形结构查询



具体的技术实现细节可以参考：

* [kaola 技术实现](doc/Tech.md)；

## 5.  案例
Kaola主要的使用场合是内部IT系统的后端，比如各类管理后台、各类信息管理系统（CRM／SCM／ERP／HIS）等。

### 单语言案例：供应链系统
Kaola最初的场景是用在一个供应链系统中。这个系统有几百张表，表间的关联复杂。应用Kaola后，整个后端代码量大大减少，所有增删改查的api都是自动生成的。最后只有三个文件，几百行代码是需要为供应链的逻辑定制的。这三个文件分别处理各类订单流水号生成逻辑、库存计算逻辑、订单流转逻辑。这些逻辑都是通过rails的数据库钩子实现的，不修改自动生成的代码，所以维护也很方便。比如下面就是序列号生成逻辑／订单流转逻辑的模版代码。

```
class ActiveRecord::Base
  before_validation :gen_seq
 
  def gen_seq
    #序列号生成逻辑
  end
end
```

```
class ActiveRecord::Base
  before_update :order_process

  def order_process
    #订单流转逻辑
  end
end
```
如果你的团队后端有ruby程序员，这是推荐使用kaola的方式，增删改查的api用kaola自动生成，其它的功能通过修改kaola的代码实现。

### 混合语言后端案例

如果你的团队后端没有ruby程序员，也可以使用kaola来帮助减少后端的开发工作量。通过采用前后端分离架构，前端开发其实不关心后端的api是用什么语言实现的。

我们在一个健康干预系统项目中采用了混合语言后端的案例。这个项目组都是java后端程序员，通过kaola来帮助java程序员完成增删改查的api，而健康干预计划／健康报告生成等功能则是独立部署的java后端实现的。

## 6. 杂项

### 发布

api网关
安全

### License
MIT License.
https://opensource.org/licenses/MIT

### 为何取名Kaola
俗话说，懒惰是程序员的美德，能够让计算机自动完成的事情，就不要重复劳动了。取名Kaola是希望这套系统让程序员可以像考拉一样悠闲，同时restful也有宁静的含义，和考拉的形象比较匹配。


2016年在高可用架构社区做的一次技术分享：

* [kaola 2016技术分享](doc/share技术分享.md)；

