# GDNetworking-X使用教程
## 创建请求
GDNetworking-X(以下简称X)是离散式的网络框架，每个请求都必须创建一个继承于GDBaseRequest的类。
如果有需要传入参数的，建议重写-initWith方法。

## 请求的URL类型
X支持三种URL类型，Server类型、CDN类型、Instagram类型。目前我们项目中只有Server和Instagram两类URL，建议请求单独复写请求基地址
### Server类型
X默认的URL类型就是server类型，建议还是复写- (NSString *)baseUrl方法，传回server基地址。
请求的地址如"/v2/login"在- (NSString *)requestURL方法中复写

### CDN类型(外部资源网址)
此类请求必须重写-(BOOL)useCDN方法并传回YES,在- (NSString *)cdnUrl方法中传回CDN基地址，其他同上。

### Instagram类型
此类请求必须重写-(BOOL)useInsta方法并传回YES,在- (NSString *)instaUrl方法中传回insta基地址,其他同上

## 请求头
重写子类- (NSDictionary *)requestHeaderFieldValueDictionary方法，给请求头

## 请求类型
重写子类- (GDRequestType)requestType方法传回请求类型，目前支持五种请求类型

## 请求序列化
非必要！针对有些需要特定序列化数据的请求，重写- (GDRequestSerializerType)requestSerializerType方法，目前支持三种方式，默认的序列化方式是HTTP，针对解密握手请求内置了两种加密方式，暂时没有这类请求。

## 返回数据序列化
针对请求返回值的序列化，默认为Json格式序列化。X提供了四种返回值序列化方式。

## Hook返回值
针对项目中需要对请求返回值进行数据处理，例如字典转模型的操作，X提供了hook的方式，子类中重写- (void)requestSuccessFilter方法，可以获取到返回数据进行处理，fail也是一样，提供了- (void)requestFailFilter方法。

## 回调
X提供了三种回调方式，SEL、block和delegate，鉴于目前项目中的代码，建议使用block回调，通过request.jsonObject和request.error分别取获取返回值或者请求错误信息。

## 缓存
X支持根据时间和版本号来处理缓存。

## 其他
具体使用可以查看demo，有关X的详细设计在readme中更新。