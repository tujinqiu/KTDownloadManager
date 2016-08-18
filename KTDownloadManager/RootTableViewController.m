//
//  RootTableViewController.m
//  KTDownloadManager
//
//  Created by Kevin on 16/8/16.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import "RootTableViewController.h"
#import "KTDownloadManager.h"
#import "DownloadTableViewCell.h"
#import "DetailViewController.h"

@interface RootTableViewController ()

@property (nonatomic, strong) NSArray *downloadModels;

@end

@implementation RootTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(tapAdd:)];
    self.tableView.tableFooterView = [UIView new];
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteModel:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[deleteItem]];
    [[UIMenuController sharedMenuController] update];
    self.downloadModels = [[KTDownloadManager sharedManager] getDownloadModels];
    if (self.downloadModels.count <= 0) {
        // 添加几个示例下载(全部是github上的公共项目)
        KTDownloadModel *model1 = [[KTDownloadModel alloc] init];
        model1.url = [NSURL URLWithString:@"https://codeload.github.com/MengTo/DesignerNewsApp/zip/master"];
        KTDownloadModel *model2 = [[KTDownloadModel alloc] init];
        model2.url = [NSURL URLWithString:@"https://codeload.github.com/hanton/HTY360Player/zip/master"];
        KTDownloadModel *model3 = [[KTDownloadModel alloc] init];
        model3.url = [NSURL URLWithString:@"https://codeload.github.com/austinzheng/iOS-2048/zip/master"];
        KTDownloadModel *model4 = [[KTDownloadModel alloc] init];
        model4.url = [NSURL URLWithString:@"https://codeload.github.com/aclissold/the-oakland-post/zip/master"];
        KTDownloadModel *model5 = [[KTDownloadModel alloc] init];
        model5.url = [NSURL URLWithString:@"https://codeload.github.com/bennyguitar/News-YC---iPhone/zip/master"];
        KTDownloadModel *model6 = [[KTDownloadModel alloc] init];
        model6.url = [NSURL URLWithString:@"https://codeload.github.com/Coding/Coding-iOS/zip/master"];
        self.downloadModels = @[model1, model2, model3, model4, model5, model6];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapAdd:(UIBarButtonItem *)button
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加下载" message:nil preferredStyle:UIAlertControllerStyleAlert];
    KTDownloadManager *manager = [KTDownloadManager sharedManager];
    KTDownloadModel *model = [[KTDownloadModel alloc] init];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"HackerNewsReader" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        model.url = [NSURL URLWithString:@"https://codeload.github.com/rnystrom/HackerNewsReader/zip/master"];
        [self testDownloadedModel:model withDownloadManager:manager];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"duckduckgo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        model.url = [NSURL URLWithString:@"https://codeload.github.com/duckduckgo/ios/zip/master"];
        [self testDownloadedModel:model withDownloadManager:manager];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"wh-app-ios" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        model.url = [NSURL URLWithString:@"https://codeload.github.com/WhiteHouse/wh-app-ios/zip/master"];
        [self testDownloadedModel:model withDownloadManager:manager];
    }];
    UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action1];
    [alert addAction:action2];
    [alert addAction:action3];
    [alert addAction:action4];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)testDownloadedModel:(KTDownloadModel *)model withDownloadManager:(KTDownloadManager *)manager
{
    NSUInteger type = [manager hasDownloadedModel:model];
    if (type == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您已下载过该资源，重新下载吗？" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"是的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [manager downloadModel:model];
            self.downloadModels = [manager getDownloadModels];
            [self.tableView reloadData];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (type == 2) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"该资源已经在下载列表！" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [manager downloadModel:model];
    }
}

- (void)deleteModel:(id)sender
{
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.downloadModels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadTableViewCell" forIndexPath:indexPath];
    KTDownloadModel *model = [self.downloadModels objectAtIndex:indexPath.row];
    [cell configWithModel:model];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 59;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    KTDownloadModel *model = [self.downloadModels objectAtIndex:indexPath.row];
    KTDownloadManager *manager = [KTDownloadManager sharedManager];
    switch (model.state) {
        case KTDownloadStateNone:
        case KTDownloadStatePaused:
            [manager downloadModel:model];
            break;
            
        case KTDownloadStateWaiting:
        case KTDownloadStateDownloading:
            [manager pauseDownloadModel:model];
            break;
            
        case KTDownloadStateFinished: {
            DetailViewController *detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
            detailVC.model = model;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return YES;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(deleteModel:)) {
        KTDownloadModel *model = [self.downloadModels objectAtIndex:indexPath.row];
        [[KTDownloadManager sharedManager] removeDownloadModel:model];
    }
}

@end
