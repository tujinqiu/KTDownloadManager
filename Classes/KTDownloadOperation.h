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
@property (nonatomic, weak, readonly) KTDownloadModel *downloadModel;
@property (nonatomic, assign) BOOL cancelToRemove;

- (instancetype)initWithDownloadModel:(KTDownloadModel *)downloadModel session:(NSURLSession *)session downloadFolderPath:(NSString *)downloadFolderPath;
- (instancetype)init NS_UNAVAILABLE;

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data;
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error;

@end

@interface NSURLSessionTask (KTDownloadOperation)

@property (nonatomic, weak) id downloadOperation;

@end
