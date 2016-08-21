//
//  KTDownloadModel.m
//  OV3D
//
//  Created by kevin.tu on 16/8/15.
//  Copyright © 2016年 ov. All rights reserved.
//

#import "KTDownloadModel.h"
#import <CommonCrypto/CommonDigest.h>

static NSString * const KTDownloadModelsDataPath = @"com.KTDownloadManager.default";

@implementation KTDownloadModel

- (instancetype)initWithUrl:(NSURL *)url
{
    if (self = [super init]) {
        _url = url;
    }
    
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _url = [NSURL URLWithString:[dict objectForKey:@"url"]];
        NSUInteger folderType = [[dict objectForKey:@"folderType"] unsignedIntegerValue];
        NSString *path = [dict objectForKey:@"downloadFilePath"];
        if (folderType == 1) {
            NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _downloadFilePath = [[docPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:path];
        }
        else if (folderType == 2) {
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _downloadFilePath = [cachesPath stringByAppendingPathComponent:path];
        }
        _state = [[dict objectForKey:@"state"] unsignedIntegerValue];
        _totalReceivedBytes = [[dict objectForKey:@"totalReceivedBytes"] unsignedIntegerValue];
        _totalBytes = [[dict objectForKey:@"totalBytes"] unsignedIntegerValue];
    }
    
    return self;
}

- (NSDictionary *)dict
{
    NSString *path = @"";
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSUInteger folderType = 0;
    if ([self.downloadFilePath hasPrefix:docPath]) {
        folderType = 1;
        path = [self.downloadFilePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", docPath] withString:@""];
    }
    else if ([self.downloadFilePath hasPrefix:cachesPath]) {
        folderType = 2;
        path = [self.downloadFilePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", cachesPath] withString:@""];
    }
    return @{@"url" : _url.absoluteString,
             @"downloadFilePath" : path,
             @"state" : [NSNumber numberWithUnsignedInteger:self.state],
             @"totalReceivedBytes" : [NSNumber numberWithLongLong:self.totalReceivedBytes],
             @"totalBytes" : [NSNumber numberWithLongLong:self.totalBytes],
             @"folderType" : [NSNumber numberWithUnsignedInteger:folderType]};
}

- (NSData *)readTotalReceivedDate
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataFile = [NSString stringWithFormat:@"%@/%@/%@", cachesPath, KTDownloadModelsDataPath, [self cachedFileNameForKey:_url.absoluteString]];
    NSData *data = [NSData dataWithContentsOfFile:dataFile];
    _totalReceivedBytes = data.length;
    
    return data;
}

- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;
}

- (void)saveReceivedData:(NSData *)data
{
    [self saveReceivedData:data toFile:nil];
}

- (void)saveReceivedData:(NSData *)data toFile:(NSString *)file
{
    if (!data) {
        return;
    }
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataFileFolder = [NSString stringWithFormat:@"%@/%@", cachesPath, KTDownloadModelsDataPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dataFileFolder]) {
        [manager createDirectoryAtPath:dataFileFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dataFileName = [dataFileFolder stringByAppendingPathComponent:[self cachedFileNameForKey:_url.absoluteString]];
    NSString *fileName = file ? file : dataFileName;
    if ([manager fileExistsAtPath:dataFileName]) {
        NSMutableData *existData = [NSMutableData dataWithContentsOfFile:dataFileName];
        [manager removeItemAtPath:dataFileName error:nil];
        [existData appendData:data];
        [existData writeToFile:fileName atomically:YES];
    }
    [data writeToFile:fileName atomically:YES];
}

- (void)removeTotalReceivedData
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataFile = [NSString stringWithFormat:@"%@/%@/%@", cachesPath, KTDownloadModelsDataPath, _url.absoluteString];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:dataFile error:nil];
}

- (void)setDownloadFilePath:(NSString *)downloadFilePath
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    BOOL pathCorrect = [downloadFilePath hasPrefix:docPath] || [downloadFilePath hasPrefix:cachesPath];
    NSAssert(pathCorrect, @"downloadFilePath必须是处于Documents或者Library/Caches文件夹下");
    _downloadFilePath = downloadFilePath;
}

- (void)setState:(KTDownloadState)state
{
    if (state == _state) {
        return;
    }
    _state = state;
    if ([self.delegate respondsToSelector:@selector(downloadModel:didChangedState:)]) {
        [self.delegate downloadModel:self didChangedState:state];
    }
}

- (void)setTotalReceivedBytes:(int64_t)totalReceivedBytes
{
    if (_totalReceivedBytes == totalReceivedBytes) {
        return;
    }
    _totalReceivedBytes = totalReceivedBytes;
    if ([self.delegate respondsToSelector:@selector(downloadModel:didReceivedTotalBytes:totalBytes:)]) {
        [self.delegate downloadModel:self didReceivedTotalBytes:totalReceivedBytes totalBytes:_totalBytes];
    }
}

@end
