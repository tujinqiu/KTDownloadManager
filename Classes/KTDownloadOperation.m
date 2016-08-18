//
//  KTDownloadOperation.m
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import "KTDownloadOperation.h"

@interface KTDownloadOperation ()

@property (nonatomic, copy) NSString *downloadFolderPath;
@property (nonatomic, weak) NSURLSession *session;
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

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
        self.downloadModel.state = KTDownloadStatePaused;
        [self exit];
        
        return;
    }
    self.executing = YES;
    self.finished = NO;
    NSData *resumeData = [self.downloadModel readResumeData];
    if (!resumeData) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadModel.url];
        [request addValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
        _downloadTask = [self.session downloadTaskWithRequest:request];
    }
    else {
        _downloadTask = [self.session downloadTaskWithResumeData:resumeData];
    }
    [_downloadTask resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadModel.state = KTDownloadStateDownloading;
    });
}

- (void)cancel
{
    [super cancel];
    
    if (self.downloadModel.state == KTDownloadStateDownloading) {
        if (self.cancelToRemove) {
            [self.downloadTask cancel];
        }
        else {
            __weak __typeof(self) weakSelf = self;
            [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                NSLog(@"produce resumedata");
                [weakSelf.downloadModel saveResumeData:resumeData];
            }];
        }
        self.downloadModel.state = KTDownloadStatePaused;
        [self exit];
    }
}

- (void)exit
{
    self.executing = NO;
    self.finished = YES;
    _downloadTask = nil;
}

#pragma mark -- NSURLSessionDownloadDelegate --

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    if (!self.downloadModel.downloadFilePath) {
        self.downloadModel.downloadFilePath = [self.downloadFolderPath stringByAppendingPathComponent:[downloadTask.response suggestedFilename]];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *folder = [self.downloadModel.downloadFilePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:folder]) {
        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [fileManager removeItemAtPath:self.downloadModel.downloadFilePath error:nil];
    [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:self.downloadModel.downloadFilePath] error:&error];
    NSLog(@"error:%@", error);
    // 避免self dealloc了，导致block代码执行无效
    KTDownloadModel *model = self.downloadModel;
    dispatch_async(dispatch_get_main_queue(), ^{
        model.state = KTDownloadStateFinished;
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadModel.totalBytes = totalBytesExpectedToWrite;
        self.downloadModel.receivedBytes = totalBytesWritten;
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadModel.totalBytes = expectedTotalBytes;
        self.downloadModel.receivedBytes = fileOffset;
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if (error) {
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            [self.downloadModel saveResumeData:resumeData];
        }
        // 避免self dealloc了，导致block代码执行无效
        KTDownloadModel *model = self.downloadModel;
        dispatch_async(dispatch_get_main_queue(), ^{
            model.error = error;
            model.state = KTDownloadStateFailed;
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

@end
