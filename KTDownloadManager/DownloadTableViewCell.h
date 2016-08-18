//
//  DownloadTableViewCell.h
//  KTDownloadManager
//
//  Created by Kevin on 16/8/16.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTDownloadManager.h"

@interface DownloadTableViewCell : UITableViewCell <KTDownloadModelDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *finishLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

- (void)configWithModel:(KTDownloadModel *)model;

@end
