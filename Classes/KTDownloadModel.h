//
//  KTDownloadModel.h
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KTDownloadState)
{
    KTDownloadStateNone = 0,            // 创建新的实例时所处状态
    KTDownloadStateWaiting,              // 等待中（前面还有正在下载的操作）
    KTDownloadStateDownloading,         // 下载中
    KTDownloadStatePaused,              // 暂停
    KTDownloadStateFinished,            // 完成
    KTDownloadStateFailed               // 失败
};

@class KTDownloadModel;

@protocol KTDownloadModelDelegate <NSObject>

// 以下代理方法在operation存在并且在下载的时候才会调用
@optional
- (void)downloadModel:(KTDownloadModel *)model didChangedState:(KTDownloadState)state;
- (void)downloadModel:(KTDownloadModel *)model didReceivedTotalBytes:(int64_t)totalReceivedBytes totalBytes:(int64_t)totalBytes;

@end

@class KTDownloadOperation;

@interface KTDownloadModel : NSObject

// 下载的url
@property (nonatomic, strong, readonly) NSURL *url;
// 下载的文件全路径，可以指定，必须处于Documents或者Library/Caches文件夹下面
// 如果为nil，那么下载完成之后使用KTDownloadManager的downloadFolderPath配合suggest name构成文件全路径
@property (nonatomic, copy) NSString *downloadFilePath;
// 已接收的总字节数
@property (nonatomic, assign) int64_t totalReceivedBytes;
// 当前接收的data，由于存在断点续传，只表示这一次下载的data，并不表示下载的总data
@property (nonatomic, strong) NSMutableData *receivedData;
// 总字节数
@property (nonatomic, assign) int64_t totalBytes;
// 下载状态
@property (nonatomic, assign) KTDownloadState state;
// 下载operation，正在下载中或者暂停一段时间之内的model会有一个operation，其他情况为nil
@property (nonatomic, weak) KTDownloadOperation *operation;
// delegate
@property (nonatomic, weak) id<KTDownloadModelDelegate> delegate;
// error
@property (nonatomic, strong) NSError *error;

- (instancetype)initWithDict:(NSDictionary *)dict;
- (instancetype)initWithUrl:(NSURL *)url;
- (instancetype)init NS_UNAVAILABLE;
- (NSDictionary *)dict;
- (NSData *)readTotalReceivedDate;
- (void)saveReceivedData:(NSData *)data;
- (void)saveReceivedData:(NSData *)data toFile:(NSString *)file;
- (void)removeTotalReceivedData;

@end
