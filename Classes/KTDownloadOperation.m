//
//  KTDownloadOperation.m
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import "KTDownloadOperation.h"
#import <objc/runtime.h>

@interface KTDownloadOperation ()

@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;
@property (nonatomic, copy) NSString *downloadFolderPath;
@property (nonatomic, weak) NSURLSession *session;
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation KTDownloadOperation

- (instancetype)initWithDownloadModel:(KTDownloadModel *)downloadModel session:(NSURLSession *)session downloadFolderPath:(NSString *)downloadFolderPath
{
    if (self = [super init]) {
        _downloadModel = downloadModel;
        _session = session;
        _downloadFolderPath = downloadFolderPath;
        _downloadModel.state = KTDownloadStateWaiting;
        _downloadModel.operation = self;
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"download operation for url:%@ dealloc", self.downloadModel.url.absoluteString);
}

- (void)start
{
    if (self.isCancelled) {
        // 避免self dealloc了，导致block代码执行无效
        KTDownloadModel *model = self.downloadModel;
        dispatch_async(dispatch_get_main_queue(), ^{
            model.state = KTDownloadStatePaused;
        });
        [self exit];
        
        return;
    }
    self.executing = YES;
    self.finished = NO;
    NSData *resumeData = [self.downloadModel readTotalReceivedDate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadModel.url];
    [request setValue:[NSString stringWithFormat:@"%lu-", (unsigned long)resumeData.length] forHTTPHeaderField:@"range"];
    [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    _dataTask = [self.session dataTaskWithRequest:request];
    _dataTask.downloadOperation = self;
    [_dataTask resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadModel.state = KTDownloadStateDownloading;
    });
}

- (void)cancel
{
    [super cancel];
    
    if (self.downloadModel.state == KTDownloadStateDownloading) {
        [self.dataTask cancel];
    }
}

- (void)exit
{
    self.executing = NO;
    self.finished = YES;
    _dataTask = nil;
}

#pragma mark -- NSURLSessionDataDelegate --

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    self.downloadModel.totalBytes = [dataTask.response expectedContentLength];
    [self.receivedData appendData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadModel.totalReceivedBytes += data.length;
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    // 避免self dealloc了，导致block代码执行无效
    KTDownloadModel *model = self.downloadModel;
    if (error) {
        if (error.code == NSURLErrorCancelled) {
            if (!self.cancelToRemove) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                NSString *acceptRange = [response.allHeaderFields objectForKey:@"Accept-Range"];
                if (acceptRange && ![acceptRange isEqualToString:@"none"]) {
                    // 保存下载数据
                    [self.downloadModel saveReceivedData:self.receivedData];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    model.state = KTDownloadStatePaused;
                });
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.error = error;
                model.state = KTDownloadStateFailed;
            });
        }
    }
    else {
        // 保存到指定文件
        NSString *file = nil;
        if (model.downloadFilePath.length > 0) {
            file = model.downloadFilePath;
        }
        else {
            NSString *suggestFileName = [task.response suggestedFilename];
            file = [self.downloadFolderPath stringByAppendingPathComponent:suggestFileName];
            model.downloadFilePath = file;
        }
        [model saveReceivedData:self.receivedData toFile:file];
        dispatch_async(dispatch_get_main_queue(), ^{
            model.state = KTDownloadStateFinished;
        });
    }
    [self exit];
}

#pragma mark -- getter and setter --

- (BOOL)isConcurrent
{
    return YES;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (NSMutableData *)receivedData
{
    if (!_receivedData) {
        _receivedData = [NSMutableData data];
    }
    
    return _receivedData;
}

@end



@implementation NSURLSessionTask (KTDownloadOperation)

static char NSURLSessionTaskDownloadOperationKey = '\0';

- (void)setDownloadOperation:(id)downloadOperation
{
    if (!downloadOperation) {
        return;
    }
    [self willChangeValueForKey:@"downloadOperation"];
    objc_setAssociatedObject(self, &NSURLSessionTaskDownloadOperationKey, downloadOperation, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"downloadOperation"];
}

- (id)downloadOperation
{
    return objc_getAssociatedObject(self, &NSURLSessionTaskDownloadOperationKey);
}

@end
