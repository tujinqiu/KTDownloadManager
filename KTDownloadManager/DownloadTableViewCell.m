//
//  DownloadTableViewCell.m
//  KTDownloadManager
//
//  Created by Kevin on 16/8/16.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import "DownloadTableViewCell.h"

@implementation DownloadTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configWithModel:(KTDownloadModel *)model
{
    [[KTDownloadManager sharedManager] setDelegate:self forModel:model];
    [self configWithModel:model state:model.state];
}

- (void)configWithModel:(KTDownloadModel *)model state:(KTDownloadState)state
{
    NSLog(@"state:%lu", (unsigned long)state);
    float progress = 0.0;
    if (model.totalBytes > 0) {
        progress = (float)model.receivedBytes / (float)model.totalBytes;
    }
    NSString *size = nil;
    if (model.totalBytes / 1024 < 1024) {
        size = [NSString stringWithFormat:@"%lldKB", model.totalBytes / 1024];
    }
    else {
        size = [NSString stringWithFormat:@"%.2fMB", (float)model.totalBytes / 1024 / 1024];
    }
    self.progressView.progress = progress;
    self.sizeLabel.text = size;
    self.urlLabel.text = model.url.absoluteString;
    switch (model.state) {
        case KTDownloadStateNone:
        case KTDownloadStatePaused:
            self.leftImageView.hidden = NO;
            self.leftImageView.image = [UIImage imageNamed:@"pause"];
            self.progressView.hidden = NO;
            self.finishLabel.hidden = YES;
            self.errorLabel.hidden = YES;
            break;
            
        case KTDownloadStateWaiting:
            self.leftImageView.hidden = NO;
            self.leftImageView.image = [UIImage imageNamed:@"waite"];
            self.progressView.hidden = NO;
            self.finishLabel.hidden = YES;
            self.errorLabel.hidden = YES;
            break;
            
        case KTDownloadStateDownloading:
            self.leftImageView.hidden = NO;
            self.leftImageView.image = [UIImage imageNamed:@"download"];
            self.progressView.hidden = NO;
            self.finishLabel.hidden = YES;
            self.errorLabel.hidden = YES;
            break;
            
        case KTDownloadStateFinished:
            self.leftImageView.hidden = YES;
            self.progressView.hidden = YES;
            self.finishLabel.hidden = NO;
            self.finishLabel.text = [NSString stringWithFormat:@"已完成:%@", [model.downloadFilePath lastPathComponent]];
            self.errorLabel.hidden = YES;
            break;
            
        case KTDownloadStateFailed:
            self.leftImageView.hidden = NO;
            self.leftImageView.image = [UIImage imageNamed:@"pause"];
            self.progressView.hidden = NO;
            self.finishLabel.hidden = YES;
            self.errorLabel.hidden = NO;
            self.errorLabel.text = [model.error localizedDescription];
            break;
            
        default:
            break;
    }
}

#pragma mark -- KTDownloadModelDelegate --

- (void)downloadModel:(KTDownloadModel *)model didChangedState:(KTDownloadState)state
{
    [self configWithModel:model state:state];
}

- (void)downloadModel:(KTDownloadModel *)model didReceivedBytes:(int64_t)receivedBytes totalBytes:(int64_t)totalBytes
{
    self.progressView.progress = (float)receivedBytes / (float)totalBytes;
    NSString *size = nil;
    if (model.totalBytes / 1024 < 1024) {
        size = [NSString stringWithFormat:@"%lldKB", model.totalBytes / 1024];
    }
    else {
        size = [NSString stringWithFormat:@"%.2fMB", (float)model.totalBytes / 1024 / 1024];
    }
    self.sizeLabel.text = size;
}

@end
