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

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _url = [NSURL URLWithString:[dict objectForKey:@"url"]];
        NSString *path = [dict objectForKey:@"downloadFilePath"];
        BOOL pathCorrect1 = [path hasPrefix:@"Documents/"];
        BOOL pathCorrect2 = [path hasPrefix:@"Library/Caches/"];
        NSAssert(path.length == 0 || pathCorrect1 || pathCorrect2, @"downloadFilePath必须是处于Documents或者Library/Caches文件夹下");
        if (pathCorrect1) {
            NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _downloadFilePath = [[docPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:path];
        }
        if (pathCorrect2) {
            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _downloadFilePath = [[cachesPath stringByReplacingOccurrencesOfString:@"Library/Caches" withString:@""] stringByAppendingPathComponent:path];
        }
        _state = [[dict objectForKey:@"state"] unsignedIntegerValue];
        _receivedBytes = [[dict objectForKey:@"receivedBytes"] unsignedIntegerValue];
        _totalBytes = [[dict objectForKey:@"totalBytes"] unsignedIntegerValue];
    }
    
    return self;
}

- (NSDictionary *)dict
{
    NSString *path = @"";
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if ([self.downloadFilePath hasPrefix:docPath]) {
        path = [self.downloadFilePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", docPath] withString:@""];
    }
    else if ([self.downloadFilePath hasPrefix:cachesPath]) {
        path = [self.downloadFilePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", cachesPath] withString:@""];
    }
    return @{@"url" : _url.absoluteString,
             @"downloadFilePath" : path,
             @"state" : [NSNumber numberWithUnsignedInteger:self.state],
             @"receivedBytes" : [NSNumber numberWithLongLong:self.receivedBytes],
             @"totalBytes" : [NSNumber numberWithLongLong:self.totalBytes]};
}

- (void)setDownloadFilePath:(NSString *)downloadFilePath
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    BOOL pathCorrect = [downloadFilePath hasPrefix:docPath] || [downloadFilePath hasPrefix:cachesPath];
    NSAssert(pathCorrect, @"downloadFilePath必须是处于Documents或者Library/Caches文件夹下");
    _downloadFilePath = downloadFilePath;
}

- (NSData *)readResumeData
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataFile = [NSString stringWithFormat:@"%@/%@/%@", cachesPath, KTDownloadModelsDataPath, [self cachedFileNameForKey:_url.absoluteString]];
    return [NSData dataWithContentsOfFile:dataFile];
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

- (void)saveResumeData:(NSData *)data
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
    if ([manager fileExistsAtPath:dataFileName]) {
        [manager removeItemAtPath:dataFileName error:nil];
    }
    [data writeToFile:dataFileName atomically:YES];
}

- (void)removeResumeData
{
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataFile = [NSString stringWithFormat:@"%@/%@/%@", cachesPath, KTDownloadModelsDataPath, _url.absoluteString];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:dataFile error:nil];
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

- (void)setReceivedBytes:(int64_t)receivedBytes
{
    if (_receivedBytes == receivedBytes) {
        return;
    }
    _receivedBytes = receivedBytes;
    if ([self.delegate respondsToSelector:@selector(downloadModel:didReceivedBytes:totalBytes:)]) {
        [self.delegate downloadModel:self didReceivedBytes:receivedBytes totalBytes:_totalBytes];
    }
}

@end
