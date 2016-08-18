//
//  KTDownloadManager.m
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import "KTDownloadManager.h"

static NSString * const KTDownloadModelsPlistFilePath = @"com.KTDownloadManager.default/models.plist";

@interface NSArray (KTDownloadOperation)

- (KTDownloadOperation *)operationForDownloadTask:(NSURLSessionDownloadTask *)task;

@end

@implementation NSArray (KTDownloadOperation)

- (KTDownloadOperation *)operationForDownloadTask:(NSURLSessionDownloadTask *)task
{
    for (KTDownloadOperation *op in self) {
        if (op.downloadTask == task) {
            return op;
        }
    }
    
    return nil;
}

@end

@interface KTDownloadManager ()<NSURLSessionDownloadDelegate>

// 下载队列，默认并发下载数量maxConcurrentOperationCount为3
@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;
// download models
@property (nonatomic, strong) NSMutableArray *downloadModels;
// nsurlsession
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation KTDownloadManager

+ (instancetype)sharedManager
{
    static KTDownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KTDownloadManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 3;
        _downloadModels = [self readDownloadModels];
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        // 监听app的退出，退出时保存saveDownloadModels
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppExit:) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)handleAppExit:(NSNotification *)notif
{
    [self saveDownloadModels:self.downloadModels];
}

- (NSMutableArray *)readDownloadModels
{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistFilePath = [cachePath stringByAppendingPathComponent:KTDownloadModelsPlistFilePath];
    NSArray *dictsArray = [NSArray arrayWithContentsOfFile:plistFilePath];
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in dictsArray) {
        KTDownloadModel *model = [[KTDownloadModel alloc] initWithDict:dict];
        [array addObject:model];
    }
    
    return array;
}

- (void)saveDownloadModels:(NSMutableArray *)downloadModels
{
    NSMutableArray *array = [NSMutableArray array];
    for (KTDownloadModel *model in downloadModels) {
        if (model.state == KTDownloadStateWaiting || model.state == KTDownloadStateDownloading) {
            [model.operation cancel];
            model.state = KTDownloadStatePaused;
        }
        NSDictionary *dict = [model dict];
        [array addObject:dict];
    }
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistFilePath = [cachePath stringByAppendingPathComponent:KTDownloadModelsPlistFilePath];
    [array writeToFile:plistFilePath atomically:YES];
}

- (NSArray<KTDownloadModel *> *)getDownloadModels
{
    return [self.downloadModels copy];
}

- (void)downloadModel:(KTDownloadModel *)model
{
    if (![self.downloadModels containsObject:model]) {
        [self.downloadModels insertObject:model atIndex:0];
    }
    if (model.state == KTDownloadStateWaiting ||
        model.state == KTDownloadStateDownloading) {
        return;
    }
    if (model.state == KTDownloadStateFinished) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        [manager removeItemAtPath:model.downloadFilePath error:&error];
        if (error) {
            model.error = error;
            model.state = KTDownloadStateFailed;
            
            return;
        }
    }
    NSOperation *op = [[KTDownloadOperation alloc] initWithDownloadModel:model session:self.session downloadFolderPath:self.downloadFolderPath];
    [self.downloadQueue addOperation:op];
}

- (void)pauseDownloadModel:(KTDownloadModel *)model
{
    if (model.state == KTDownloadStateNone ||
        model.state == KTDownloadStatePaused ||
        model.state == KTDownloadStateFinished) {
        return;
    }
    [model.operation cancel];
}

- (void)cancelDownloadModel:(KTDownloadModel *)model
{
    if (model.state == KTDownloadStateNone ||
        model.state == KTDownloadStatePaused ||
        model.state == KTDownloadStateFinished) {
        return;
    }
    model.operation.cancelToRemove = YES;
    [model.operation cancel];
}

- (void)removeDownloadModel:(KTDownloadModel *)model
{
    [self cancelDownloadModel:model];
    [model removeResumeData];
    [self.downloadModels removeObject:model];
}

- (NSUInteger)hasDownloadedModel:(KTDownloadModel *)model
{
    for (KTDownloadModel *tmp in self.downloadModels) {
        if ([tmp.url.absoluteString isEqualToString:model.url.absoluteString]) {
            return tmp.state == KTDownloadStateFinished ? 1 : 2;
        }
    }
    
    return 0;
}

- (void)setDelegate:(id<KTDownloadModelDelegate>)delegate forModel:(KTDownloadModel *)model
{
    for (KTDownloadOperation *op in self.downloadQueue.operations) {
        if (op.downloadModel.delegate == delegate) {
            op.downloadModel.delegate = nil;
        }
    }
    model.delegate = delegate;
}

@synthesize downloadFolderPath = _downloadFolderPath;

- (void)setDownloadFolderPath:(NSString *)downloadFolderPath
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    BOOL pathCorrect = [downloadFolderPath hasPrefix:docPath] || [downloadFolderPath hasPrefix:cachesPath];
    NSAssert(pathCorrect, @"downloadFilePath必须是处于Documents或者Library/Caches文件夹下");
    _downloadFolderPath = downloadFolderPath;
}

- (NSString *)downloadFolderPath
{
    if (!_downloadFolderPath) {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _downloadFolderPath = [docPath stringByAppendingPathComponent:@"KTDownloads"];
    }
    
    return _downloadFolderPath;
}

- (void)setMaxRunningDownloadNumber:(NSUInteger)maxRunningDownloadNumber
{
    NSAssert(maxRunningDownloadNumber > 0, @"maxRunningDownloadNumber必须大于0");
    
    _downloadQueue.maxConcurrentOperationCount = maxRunningDownloadNumber;
}

- (NSUInteger)maxRunningDownloadNumber
{
    return _downloadQueue.maxConcurrentOperationCount;
}

#pragma mark -- NSURLSessionDownloadDelegate --

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    KTDownloadOperation *op = [self.downloadQueue.operations operationForDownloadTask:downloadTask];
    [op URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    KTDownloadOperation *op = [self.downloadQueue.operations operationForDownloadTask:downloadTask];
    [op URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    KTDownloadOperation *op = [self.downloadQueue.operations operationForDownloadTask:downloadTask];
    [op URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    KTDownloadOperation *op = [self.downloadQueue.operations operationForDownloadTask:(NSURLSessionDownloadTask *)task];
    [op URLSession:session task:task didCompleteWithError:error];
}

@end
