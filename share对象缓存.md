# HTTP应用的动态请求缓存方案

这次的分享主要讲讲HTTP应用的后端动态请求缓存方案。动态请求的缓存主要分为两大部分：1.基于Etag的缓存，客户端可感知的；2.服务器端的内部缓存，是客户端不可感知的。

## 0. HTTP的缓存

早期的HTTP协议是为静态web文件传输服务的，所设计的缓存协议也是针对静态文件的。Http协议的1.0版本有一套基于时间的静态文件缓存方案。Cache-Control与Expires用于控制浏览器缓存文件的时间间隔，在给定的缓存时间内浏览器无须访问服务器下载文件的新版本。针对时间的缓存还有Last-Modified机制，每次浏览器都访问服务器，如果文件无变更，那么服务器返回304响应，而不重新发送静态文件。

但是上面的这套缓存协议不能满足日益复杂的Web应用的需求，主要的问题有两点：

1. 随着网络规模的增长，Web服务器往往是一个集群。同一个文件在集群内不同的机器上的修改时间不一致，而且Last-Modified的时间精度只能到秒级。这导致基于Last-Modified机制的文件缓存有漏洞。

2. 更重要的是Web越来越动态化，对于一个后端提供的json API，根本就没有所谓的最后修改时间。

这就导致了基于文件内容指纹的方案。很多Web开发框架的缓存方案也经历了从时间戳到文件指纹的缓存机制升级的过程。比如Rails开发框架在2.0版本有一个基于时间戳的缓存方案，所有的js文件，url中自动带上最后修改修改时间，比如：

   xxx.js?v=1482287874
   
然后在Rails3.0框架中，这套方案更改为基于文件内容Hash的文件重命名方案，比如：

   xxx_hash.js

HTTP协议在1.1版本中增加了基于Etag的指纹缓存方案。下面是一个Etag使用的例子：


curl -g --head 'http://scm.laobai.com:9391/tpsy_evaluation_questions.json?s[tpsy_evaluation_main_id]=4&many=tpsy_evaluation_options'

>HTTP/1.1 200 OK
>ETag: W/"758e07c4f86f8eaf09d590ef9f23e4d6"
>...


curl -g --head -H 'If-None-Match: W/"758e07c4f86f8eaf09d590ef9f23e4d6"'  'http://scm.laobai.com:9391/tpsy_evaluation_questions.json?s[tpsy_evaluation_main_id]=4&many=tpsy_evaluation_options'


ngrep -d eth0  -W byline 'tpsy' port 3000


这里例子里的Etag以‘W’开发，这是所谓的Weak Etag。产生Weak Etag的场景主要是内容压缩。Nginx1.7之前有一个Etag相关的Bug，而nginx开发组不认为是自己的bug。当后端Web服务器提供的响应经过nginx压缩的时候，nginx会删除响应头里的etag。Nginx开发组的理由是，经过压缩后，文件内容已经变更，所以原来的etag必须删除。

后来nginx和后端server各退一步，后端server提供Weak Etag，而nginx不删除Weak Etag。从Nginx1.7.3版本开始，其gzip模块能正确的处理Weak Etag了。如果response中带Weak Etag，那么Nginx的gzip模块不处理；如果response中带strong Etag，那么Nginx的gzip模块会把它转化为Weak Etag。

Weak Etag和 (strong) ETag的区别在于：Etag保证文件的内容是完全相同的，而Weak Etag只保证文件的内容是语义上相同的。区分ETag和Weak Etag对一些byte by byte的操作有影响，比如断点续传等。


彻底弄懂 Http 缓存机制 - 基于缓存策略三要素分解法
https://segmentfault.com/p/1210000007850705?utm_source=weekly&utm_medium=email&utm_campaign=email_weekly

Rails / Nginx 与 Weak Etag
https://ruby-china.org/topics/23193

【Web缓存机制系列】2 – Web浏览器的缓存机制
http://www.alloyteam.com/2012/03/web-cache-2-browser-cache/

HTTP 缓存
https://developers.google.cn/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=zh-cn

## 1. 内存模型

### Linux内存模型
进程／线程，
OS／Program

进程、线程及其内存模型
http://buptjz.github.io/2014/04/23/processAndThreads

探索 Linux 内存模型
https://www.ibm.com/developerworks/cn/linux/l-memmod/


### java内存模型
volatile
cpu私有缓存／L2L3共享缓存／主存

深入理解Java内存模型（一）——基础
http://www.infoq.com/cn/articles/java-memory-model-1

Jvm内存模型
http://gityuan.com/2016/01/09/java-memory/


### Web应用内存模型
内存／外部内存缓存memcache／数据库
一级缓存／二级缓存

## 2. Web对象缓存系统的设计
### 客户端可见 vs 客户端不可见
### 缓存key的设计
### 缓存key的遍历
### 缓存清除
### 缓存过期


## 2. 单个对象的缓存
### Key的设计
namespace ／ class ／ id
主动清除缓存

### Memcache缓存数据库
function find_with_cache(id)
  memcache

### 控制流抽象

template方法模式

def with_cache(hash,key)
  value = hash[key]
  return value if value
  value = yield
  hash[key]=value
  value
end

## 3. Request缓存
ThreadLocal
IdentifyMap

## 4. 列表对象的缓存
### Key的设计
namespace ／ class ／ timestamp ／ list

利用timestamp切换缓存，被动过期


## 5. 缓存请求合并

https://github.com/memcached/memcached/wiki/BinaryProtocolRevamped

getq

https://github.com/memcached/memcached/blob/master/doc/protocol.txt

gets


getq vs gets ??

## 分布式锁



## 6. 缓存穿透


比如说：某个查询数据库的接口，因为调用量比较大，所以加了缓存，并设定缓存过期后刷新，问题是当并发量比较大的时候，如果没有锁机制，那么缓存过期的瞬间，大量并发请求会穿透缓存直接查询数据库，造成雪崩效应，如果有锁机制，那么就可以控制只有一个请求去更新缓存，其它的请求视情况要么等待，要么使用过期的缓存。






