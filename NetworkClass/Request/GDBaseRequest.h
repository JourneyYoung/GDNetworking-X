//
//  GDBaseRequest.h
//  GDNetwork
//
//  Created by Journey on 2018/3/12.
//  Copyright © 2018年 GoDap. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const GDNetworkErrorDomain;

///请求方式结构体
typedef NS_ENUM(NSInteger, GDRequestType){
    ///这就不用注释了吧。。。
    GDRequestTypeGET = 0,
    GDRequestTypePOST,
    GDRequestTypeHEAD,
    GDRequestTypePUT,
    GDRequestTypeDELETE,
    GDRequestTypePATCH
};

///这里是本地请求验证返回的错误码
typedef NS_ENUM (NSInteger, GDNetworkErrorCode) {
    /// 返回json数据校验错误
    GDNetworkJSONValidateError = -1001,
    /// 状态码错误,与`responseValidator`关联
    GDNetworkResponseValidateError = -1000,
    /// 返回的NSURLResponse错误（返回的不是NSHTTPURLResponse）
    GDNetworkInvaildResponseType = -999,
    /// 返回的数据类型应该是NSData
    GDNetworkInvaildResponseDataType = -998,
    /// 缓存时间不合法
    GDNetworkInvalidCacheInSeconds = -997,
    /// 没有相应的缓存
    GDNetworkInvaildCache = -996,
    /// 缓存配置文件错误
    GDNetworkInvaildCacheMetadata = -995,
    /// 缓存失效
    GDNetworkCacheExpired = -994,
    /// 缓存版本号不匹配
    GDNetworkCacheVersionNotMatch = -993,
    /// APP版本号不匹配
    GDNetworkCacheAPPVersionNotMatch = -992,
    /// 缓存写入失败
    GDNetworkWriteCacheFailed = -991,
    /// 加密密钥失效
    GDNetworkEncryptionKeyExpired = -990,
    /// 加密握手失败
    GDNetworkEncryptionHandShakeFail = -889
};

///返回instagram请求错误码
typedef NS_ENUM(NSInteger, GDInstaNetworkErrorCode) {
    ///登录错误，密码不正确
    GDInstaNetworkErrorCodePasswordIncorrect = 0,
    ///广义登录失败
    GDInstaNetworkErrorCodeLoginError,
    ///错误类型太多了，等到应用到应用层的时候再写
    GDInstaNetworkErrorCodeFollowerError
};

///请求序列化格式
typedef NS_ENUM(NSInteger, GDRequestSerializerType){
    ///Json序列化
    GDRequestSerializerTypeJSON = 0,
    ///Http
    GDRequestSerializerTypeHTTP,
    ///加密请求
    GDRequestSerializerTypeEncryption
};

///返回值序列化格式
typedef NS_ENUM(NSInteger, GDResponseSerializerType){
    ///UTF-8 string对象
    GDResponseSerializerTypeString = 0,
    ///Json序列化
    GDResponseSerializerTypeJSON,
    GDResponseSerializerTypeDecryption,
    GDResponseSerializerTypeData
};

///请求状态
typedef NS_ENUM(NSInteger, GDRequestState) {
    ///请求准备中
    GDRequestStatePrepare = 0,
    ///正在请求中
    GDRequestStateRunning,
    ///请求暂停
    GDRequestStateSuspend,
    ///请求取消
    GDRequestStateCancelled,
    ///请求完成
    GDRequestStateCompleted
};

///请求优先级
typedef NS_ENUM(NSInteger, GDRequestPriority){
    GDRequestPriorityHigh = 1000,
    GDRequestPriorityDefualt = 750,
    GDRequestPriorityLow = 250,
};

@class GDBaseRequest;
@class GDRequestFormData;
@class GDNetworkConsole;
@class GDBaseRequestInternal;

/// 请求进度block
typedef void (^GDRequestProgressBlock)(__kindof NSProgress *progress);
/// 请求结束回调block
typedef void (^GDRequestCompletionBlock)(__kindof GDBaseRequest *request);
/// 重定向block
typedef NSURLRequest *_Nullable (^GDRequestWillRedirectionBlock)(NSURLSession * _Nonnull session, NSURLSessionTask *_Nonnull task, NSURLResponse *_Nonnull response, NSURLRequest *_Nonnull redirectRequest);


///请求完成代理回调
@protocol GDBaseRequestDelegate <NSObject>

@optional

///缓存命中
- (void)cacheHitted:(__kindof GDBaseRequest *)request;

///请求成功
- (void)requestSucced:(__kindof GDBaseRequest *)request;

///请求失败
- (void)requestFailed:(__kindof GDBaseRequest *)request;

@end

///请求状态接口
@protocol GDBaseRequestStateProtocol <NSObject>

@optional
///请求即将开始
- (void)requestWillStart:(__kindof GDBaseRequest *)request;

///请求开始
- (void)requestDidStart:(__kindof GDBaseRequest *)request;

///请求即将结束
- (void)requestWillStop:(__kindof GDBaseRequest *)reqeust;

///请求结束
- (void)requestDidStop:(__kindof GDBaseRequest *)request;

@end
///以上是请求相关的回调

@interface GDBaseRequest : NSObject

/// 请求的task
@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *task;
///请求的request
@property (nonatomic, strong, readonly, nullable) NSURLRequest *request;

@property (nonatomic, strong, readonly, nullable) NSURLRequest *originalRequest;

@property (nonatomic, strong, readonly, nullable) NSURLResponse *response;


///  The response status code.
@property (nonatomic, readonly) NSInteger responseStatusCode;

///  The response header fields.
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;

/**
 return NSData
 if(GDResponseSerializationData),will return decode data
 */
@property (nonatomic, strong, readonly, nullable) NSData *responseData;

///  The String serialized by string type
@property (nonatomic, copy, readonly, nullable) NSString *responseString;

///  The Object serialized by json type
@property (nonatomic, strong, nullable) id responseJSONObject;

///  This tag is used for discriminating request
@property (nonatomic) NSInteger tag;

///  This error can be either serialization error or network error. If nothing wrong happens
///  this value will be nil.
@property (nonatomic, strong, readonly, nullable) NSError *error;

///  Return cancelled state of request task.
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

///  Executing state of request task.
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;


/**
 The state of request
 
 @note Can use KVO
 */
@property (nonatomic, readonly) GDRequestState requestState;


/// delegate for protocol
@property (nonatomic, weak, nullable) id<GDBaseRequestDelegate> delegate;

/// request success callback
@property (nonatomic, copy, nullable) GDRequestCompletionBlock successCompletionBlock;

/// request failed callback
@property (nonatomic, copy, nullable) GDRequestCompletionBlock failureCompletionBlock;

/// The progress of uploading
@property (nonatomic, copy, nullable) GDRequestProgressBlock uploadProgressBlock;

/// redirectionBlock
@property (nonatomic, copy, nullable) GDRequestWillRedirectionBlock redirectionBlock;

/// The priority of request
@property (nonatomic, assign) GDRequestPriority requestPriority;



/// Start the request and set success callback and fail callback at the same time
- (void)startWithSuccessBlock:(nullable GDRequestCompletionBlock)successBlock
                 failureBlock:(nullable GDRequestCompletionBlock)failureBlock;

///Action

/// set block nil to prevent duplicate references
- (void)clearCompletionBlock;

/// suspend request
- (void)suspend;

/// resume the request
- (void)resume;

/// start request
- (void)start;

/// start request without any cache
- (void)startWithoutCache;

///停止
/**
 取消请求
 
 @description 对于执行中的请求才会生效
 <p>   执行本方法成功之后请求会返回`NSURLErrorCancelled`，并且对于下载请求，默认是
 会保存请求的断点续传数据，如果需要cancel的时候不保存断点续传数据需要在
 `saveResumeDataWhileCancelDownloadRequest`中返回NO
 */
- (void)stop;

- (void)startWithCompletionBlockWithSuccess:(_Nullable GDRequestCompletionBlock)success
                                    failure:(_Nullable GDRequestCompletionBlock)failure;

/**
 添加请求成功的Target-Action
 
 @description 可以设置多个target-action回调
 
 @param target target
 @param action action
 */
- (void)addTarget:(nullable id)target successAction:(SEL)action;

/**
 添加请求失败的Target-Action
 
 @description 可以设置多个target-action回调
 
 @param target target
 @param action action
 */
- (void)addTarget:(nullable id)target failureAction:(SEL)action;


/// 请求状态的代理，主要回调请求开始于结束的状态
@property (nonatomic, readonly, nullable) NSMutableSet<id<GDBaseRequestStateProtocol> > *requestAccessories;

/**
 添加请求状态的代理
 
 @param requestAccessory 请求状态代理对象
 */
- (void)addReuestAccessory:(id<GDBaseRequestStateProtocol>)requestAccessory;

/**
 * 该类的子类通过override以下方法来自由定义
 */

@end

@interface GDBaseRequest (BasRequestInfo)


///基地址，子类不应该经常复写这个值，在全局中定义
- (NSString *)baseUrl;

///ins接口的基地址
- (NSString *)insBaseUrl;

///请求地址
- (NSString *)requestUrl;

///超时时间,defualt is 60s
- (NSInteger)timeoutInterval;

///请求方式
- (GDRequestType)requestType;

///请求序列化方式
- (GDRequestSerializerType)requestSerializerType;

///返回值序列化方式
- (GDResponseSerializerType)responseSerializerType;

///参数
- (nullable id)params;

- (GDNetworkConsole *)requestConsole;

/**
 请求的表单数据
 
 @warning 只有`POST`请求才允许带表单数据
 */
- (nullable NSArray<GDRequestFormData *> *)requestFormData;

/**
 自定义请求
 
 @warning requestUrl／baseUrl／reuquestArgument／reuquestArgument／requestMethod／
 requestSerializer/requestFormData属性会在Override customeRequest之后失效
 
 @note 默认为nil
 */
- (nullable NSURLRequest *)customeRequest;

///是否使用外部资源基地址，例如获取图片等功能，在userInsUrl判断为假时使用,Defualt NO;
- (BOOL)useSourceUrl;

///是否允许使用移动网络。3G,4G等,default is YES
- (BOOL)allowsMovableSignal;

/**
 请求的优先级
 
 @note 默认为`GDRequestPriorityDefault`
 */
- (GDRequestPriority)requestPriority;


/**
 请求验证信息
 用于请求中需要带上user信息的接口
 @note 默认为nil
 */
- (nullable NSString *)requestAuthorizationUsername;
- (nullable NSString *)requestAuthorizationPassword;

/**
 请求自定义HTTP头
 
 @note 默认为nil
 */
- (nullable NSDictionary *)requestHeaderFieldValueDictionary;

///请求错误信息
@property (nonatomic, strong, readonly, nullable) NSError *responseError;

///请求进度
@property (nonatomic, assign) float requestProgress;

/**
 请求成功回调
 请求成功之后会首先执行这个方法，可以在方法内部进行数据Model化
 */
- (void)requestSuccessFilter;


/**
 请求失败回调
 请求失败之后会首先执行这个方法，可以在方法内部进行异常处理
 */
- (void)requestFailureFilter;

/**
 JSON校验工具
 
 @code
 - (nullable id)jsonValidator {
 return @[@{@"name":[NSNumber class]}]]
 }
 @endcode
 
 @note 判断返回JSON数据进行值以及类型或者校验，如果校验失败，则请求被认定为请求失败
 */
- (nullable id)jsonValidator;

/**
 返回校验
 
 @description 可以在此方法中进行返回数据的校验，例如状态码校验,responseValidator比jsonValidator有更高的优先级，
 若responseValidator校验失败则认为请求失败并且执行请求失败的回调
 
 @note 默认是对状态码进行校验，状态码在200~299范围内才认为请求成功
 */
- (BOOL)responseValidator;

@end

#pragma mark - Upload request

@interface GDBaseRequest(Upload)

/**
 上传请求
 
 @note默认为`nil`
 
 @warning 如果设置此值则认定此请求为上传请求，请求其他属性全部忽略
 */
- (nullable NSURLRequest *)fileUploadRequest;

/**
 上传的文件URL
 
 @note 默认为`nil`
 */
- (nullable NSURL *)uploadFileURL;

/**
 上传的二进制数据
 
 @description 请求会优先取`uploadFileData`作为上传数据
 @note 默认为`nil`
 */
- (nullable NSData *)uploadFileData;

@end

#pragma mark - Download request

@interface GDBaseRequest(Download)

/// 请求下载进度
@property (nonatomic, copy, nullable) GDRequestProgressBlock downloadProgressBlock;

/// 续传数据保存的地址
@property (nonatomic, strong, readonly, nullable) NSURL *downloadResumeDataURL;

/// 文件下载地址
@property (nonatomic, strong, readonly, nullable) NSURL *downloadDestinationURL;

/**
 下载的请求，与GDBaseRequest其他属性没有关联
 
 @note 默认为`nil`
 @warning 如果设置此值则认定此请求为下载请求，请求其他属性全部忽略
 */
- (nullable NSURLRequest *)fileDownloadRequest;

/**
 调用[GDBaseRequest stop]的时候是否保存`断点续传数据`
 
 @note 默认为`YES`
 */
- (BOOL)saveResumeDataWhileCancelDownloadRequest;

/**
 断点续传数据
 
 @note 默认为`downloadResumeDataURL`文件内容
 */
- (NSData *)downloadRequestResumeData;

/**
 文件保存地址
 
 @note 默认为`nil`，下载会保存在cache文件夹中
 
 @see [GDConfigureManager downloadDirectory]
 */
- (nullable NSURL *)downloadDirectory;

@end


#pragma mark - CDN

@interface GDBaseRequest (CDN)

/**
 是否使用CDN的host地址
 
 @note 默认为`NO`
 */
- (BOOL)useCDN;

/**
 cdn的host地址
 
 @note userCDN返回为`YES`时，将会使用`cdnUrl`替代请求参数中的基地址`baseUrl`
 @note 默认为`nil`
 */
- (nullable NSString *)cdnUrl;

/**
 是否使用CDN的host地址
 
 @note 默认为`NO`
 */
- (BOOL)useInsta;

/**
 cdn的host地址
 
 @note userCDN返回为`YES`时，将会使用`cdnUrl`替代请求参数中的基地址`baseUrl`
 @note 默认为`nil`
 */
- (nullable NSString *)instaUrl;

@end

#pragma mark - Cache

/*!
 * 请求的缓存
 * @important 下载以及上传请求没有缓存
 */
@interface GDBaseRequest (Cache)

/// 缓存命中的回调Block
@property (nonatomic, copy, nullable) GDRequestCompletionBlock cacheHittedBlock;
/// 缓存是否命中
@property (nonatomic, assign, readonly, getter=isCacheHited) BOOL cacheHited;
/// 缓存错误信息
@property (nonatomic, strong, readonly, nullable) NSError *cacheError;

/**
 添加Cache回调的Target-Action
 
 @description 可以设置多个target-action回调
 
 @param target target
 @param action action
 */
- (void)addTarget:(nullable id)target cacheHittedAction:(SEL)action;

/**
 请求缓存命中回调
 请求缓存命中之后会首先执行这个方法，可以在方法内部进行数据Model化
 */
- (void)requestCacheHittedFilter;

/**
 设置请求的成功、请求缓存命中以及请求失败的回调Block并且发起请求
 
 @description 本方法会考虑请求的缓存

 
 @param successBlock     请求成功的回调Block
 @param cacheHittedBlock 请求缓存命中的回调Block
 @param failureBlock     请求失败的回调Block
 */
- (void)startWithSuccessBlock:(nullable GDRequestCompletionBlock)successBlock
             cacheHittedBlock:(nullable GDRequestCompletionBlock)cacheHittedBlock
                 failureBlock:(nullable GDRequestCompletionBlock)failureBlock;

/**
 是否忽略缓存
 
 @note 默认为`YES`
 */
- (BOOL)ignoreCache;

/**
 决定缓存命中的时候是否仍进行请求
 
 @note 默认为`NO`，会进行请求
 
 @warning 如果返回`YES`,则回调是走请求成功；如果返回`NO`,则回调是先走缓存命中，请求完成之后会走请求成功
 */
- (BOOL)invalidateRequestWhileCacheHited;

/**
 @description 请求的method，url，cacheSensitiveArgument将决定请求缓存文件名，再去通过缓存文件名去查找缓存文件。
 可以断定三个元素之中有任何一个不一样就认定为改请求没有缓存
 @note 默认为`nil`
 */
- (nullable id)cacheSensitiveArgument;

/**
 缓存保存时间
 
 @note 默认为`0`
 */
- (NSTimeInterval)cacheTimeInSeconds;

/**
 缓存的版本号
 
 @note 默认为`0`
 */
- (long long)cacheVersion;

/**
 清空当前版本缓存
 */
- (BOOL)cleanCache;

@end



NS_ASSUME_NONNULL_END
