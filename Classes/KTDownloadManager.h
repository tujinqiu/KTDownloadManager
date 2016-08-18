//
//  KTDownloadManager.h
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTDownloadOperation.h"

@interface KTDownloadManager : NSObject

// 下载保存目录，默认是Documents/KTDownloads
@property (nonatomic, copy) NSString *downloadFolderPath;
// 同时下载最大个数
@property (nonatomic, assign) NSUInteger maxRunningDownloadNumber;

// 单例
+ (instancetype)sharedManager;
// 获取models
- (NSArray<KTDownloadModel *> *)getDownloadModels;
// 启动下载，加入下载队列，必须处于KTDownloadStateNone，KTDownloadStatePaused或者KTDownloadStateFinished状态，否则啥都不干
// KTDownloadStateFinished状态下启动下载会删除原来的下载内容重新下载
- (void)downloadModel:(KTDownloadModel *)model;
// 暂停下载，必须处于KTDownloadStateWating或者KTDownloadStateDownloading状态，否则啥都不干
- (void)pauseDownloadModel:(KTDownloadModel *)model;
// 删除一个，如果正在下载，那么停止，并且删除数据
- (void)removeDownloadModel:(KTDownloadModel *)model;
// 查询某个model是否已下载
// return 0-没有被下载，1-已经下载完成，2-已经处于下载列表中
- (NSUInteger)hasDownloadedModel:(KTDownloadModel *)model;
// 给model添加代理，避免多个model公用一个代理的情况
- (void)setDelegate:(id<KTDownloadModelDelegate>)delegate forModel:(KTDownloadModel *)model;

@end
