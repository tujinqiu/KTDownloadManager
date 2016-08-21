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
        KTDownloadModel *model1 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://nj02all01.baidupcs.com/file/03a6d53a1816ffe4bc61989af96ae8ca?bkt=p3-00002b6c4fd69b62bd76de416911e033a448&fid=3238670166-250528-876280113316255&time=1471662986&sign=FDTAXGERLBH-DCb740ccc5511e5e8fedcff06b081203-R0VzZlYfdi9YRYTHFhyUrtVu2Og%3D&to=nj2hb&fm=Yan,B,T,t&sta_dx=31082932&sta_cs=1&sta_ft=zip&sta_ct=4&sta_mt=4&fm2=Yangquan,B,T,t&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=00002b6c4fd69b62bd76de416911e033a448&sl=75038799&expires=8h&rt=sh&r=546480087&mlogid=5391629881511995899&vuk=3238670166&vbdid=1194279313&fin=Eleven-master.zip&fn=Eleven-master.zip&slt=pm&uta=0&rtype=1&iv=0&isw=0&dp-logid=5391629881511995899&dp-callid=0.1.1&hps=1"]];
        KTDownloadModel *model2 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/hanton/HTY360Player/zip/master"]];
        KTDownloadModel *model3 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/austinzheng/iOS-2048/zip/master"]];
        KTDownloadModel *model4 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/aclissold/the-oakland-post/zip/master"]];
        KTDownloadModel *model5 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/bennyguitar/News-YC---iPhone/zip/master"]];
        KTDownloadModel *model6 = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/Coding/Coding-iOS/zip/master"]];
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
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"HackerNewsReader" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        KTDownloadModel *model = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/rnystrom/HackerNewsReader/zip/master"]];
        [self testDownloadedModel:model withDownloadManager:manager];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"duckduckgo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        KTDownloadModel *model = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/duckduckgo/ios/zip/master"]];
        [self testDownloadedModel:model withDownloadManager:manager];
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"wh-app-ios" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        KTDownloadModel *model = [[KTDownloadModel alloc] initWithUrl:[NSURL URLWithString:@"https://codeload.github.com/WhiteHouse/wh-app-ios/zip/master"]];
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
