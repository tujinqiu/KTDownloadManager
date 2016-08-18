//
//  KTDownloadOperation.h
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTDownloadModel.h"

@interface KTDownloadOperation : NSOperation

// 每个operation必须有一个model
@property (nonatomic, strong, readonly) KTDownloadModel *downloadModel;
@property (nonatomic, strong, readonly) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) BOOL cancelToRemove;

- (instancetype)initWithDownloadModel:(KTDownloadModel *)downloadModel session:(NSURLSession *)session downloadFolderPath:(NSString *)downloadFolderPath;
- (instancetype)init NS_UNAVAILABLE;

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location;
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error;

@end
