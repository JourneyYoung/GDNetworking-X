# GDNetworking-X

[![CI Status](http://img.shields.io/travis/journeyyoung/GDNetworking-X.svg?style=flat)](https://travis-ci.org/journeyyoung/GDNetworking-X)
[![Version](https://img.shields.io/cocoapods/v/GDNetworking-X.svg?style=flat)](http://cocoapods.org/pods/GDNetworking-X)
[![License](https://img.shields.io/cocoapods/l/GDNetworking-X.svg?style=flat)](http://cocoapods.org/pods/GDNetworking-X)
[![Platform](https://img.shields.io/cocoapods/p/GDNetworking-X.svg?style=flat)](http://cocoapods.org/pods/GDNetworking-X)

## Installation

GDNetworking-X is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GDNetworking-X'
```

## Author

journey, yy.journeyyoung@gmail.com

## License

GDNetworking-X is available under the MIT license. See the LICENSE file for more info.


## 简介

GDNetworking-X是我们在项目中沉淀下来的，贴合复杂业务逻辑和多种APP不同网络情况的复杂网络架构，底层请求没有重复造轮子，使用的是业内使用最广泛的OC网络框架 **AFNetworing**，业务上进行拓展，提供了多种定制化接口，尤其适合不同API不同处理的业务场景。

## 设计

总体结构：离散式网络框架结构

### 思维导图

![](https://journeyblogimage.oss-cn-shanghai.aliyuncs.com/GDNetworking-X.png)

### 流程图

![](https://journeyblogimage.oss-cn-shanghai.aliyuncs.com/GDNetworking-X%E6%B5%81%E7%A8%8B%E5%9B%BE.jpg)

### 主要数据类图设计

![](https://journeyblogimage.oss-cn-shanghai.aliyuncs.com/GDNetworking-X%E7%B1%BB%E5%9B%BE%20%281%29.jpg)

### 时序图

![](https://journeyblogimage.oss-cn-shanghai.aliyuncs.com/GDNetworking-X%E6%97%B6%E5%BA%8F%E5%9B%BE.jpg)

## 使用方法

每一个独立的API请求类继承于GDBaseRequest父类。在子类中重写父类的方法以达到自定义的目的，如果中途接入，可以自己再定义一个基类BaseRequest继承于GDBaseRequest来进行拓展。

### 初始化

在Appdelegate中初始化完应用后进行全局的网络环境配置

```ruby
GDNetEnvironmentConfigureManager *config = [GDNetEnvironmentConfigureManager defaultConfiguration];
config.baseUrl = @"www.github.com";

```

### 创建请求

GDNetworking-X(以下简称X)是离散式的网络框架，每个请求都必须创建一个继承于GDBaseRequest的类,然后复写父类属性和方法
如果接口有需要传入固定参数的，可以重写-initWith方法。

### 请求的URL类型

X支持三种URL类型，Server类型、CDN类型，建议请求单独复写请求基地址

#### Server类型
X默认的URL类型就是server类型，基地址可全局配置完毕，仅在子类中单独复写**requestURL**方法来传入请求API

#### CDN类型(外部资源网址)
此类请求必须重写useCDN方法并传回YES,在**cdnUrl**方法中传回CDN基地址，其他同上。


### 请求头
重写子类**requestHeaderFieldValueDictionary**方法，给请求头

### 请求类型
重写子类**requestType**方法传回请求类型，目前支持五种请求类型

### 请求参数
重写子类**param**方法传入请求参数，以NSDictionary的形式

### 请求序列化
非必要！针对有些需要特定序列化数据的请求，重写**requestSerializerType**方法，目前支持三种方式，默认的序列化方式是HTTP，针对解密握手请求内置了两种加密方式，具体请看源码。

### 返回数据序列化
针对请求返回值的序列化，默认为Json格式序列化。X提供了四种返回值序列化方式。

### Hook返回值
针对项目中需要对请求返回值进行数据处理，例如字典转模型的操作，X提供了hook的方式，子类中重写**requestSuccessFilter**方法，可以获取到返回数据进行处理，fail也是一样，提供了**requestFailFilter**方法。利用这种hook的方式，可以在子类API中完成数据处理，例如，判空处理，字典转模型处理，业务层直接从api中取出完好的数据，保证了数据的纯净性。

### 回调
X提供了三种回调方式，SEL、block和delegate，鉴于目前项目中的代码，建议使用block回调，通过request.jsonObject和request.error分别取获取返回值或者请求错误信息。

### 缓存
X支持根据时间和版本号来处理缓存。

### 上传
X针对流处理上传进行了优化，将文件进行分片，多线程分片进行上传以加速上传的过程，当然这一行为需要服务器的支持。

### 下载
X支持断点续传等常规下载功能，沙盒地址可以自行配置，每一个下载API都会自动读取断点数据，即取消当前下载API，重新创建下载请求，也是从断点开始继续下载的。

## 其他
X实际是一个机遇AFNetworking内核，面向业务进行封装的多功能网络架构，能够满足几乎所有的业务场景。其功能远不止这些，具体请参见demo和源码。

