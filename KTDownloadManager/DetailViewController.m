//
//  DetailViewController.m
//  KTDownloadManager
//
//  Created by Kevin on 16/8/16.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.urlLabel.text = [NSString stringWithFormat:@"地址：%@", self.model.url.absoluteString];
    int64_t size = self.model.totalBytes / 1024;
    if (size < 1024) {
        self.sizeLabel.text = [NSString stringWithFormat:@"大小：%lldk", size];
    }
    else {
        self.sizeLabel.text = [NSString stringWithFormat:@"大小：%lldM", size / 1024];
    }
    self.locationLabel.text = [NSString stringWithFormat:@"存储位置：%@", self.model.downloadFilePath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
