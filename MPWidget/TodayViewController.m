//
//  TodayViewController.m
//  MPWidget
//
//  Created by mopellet on 2017/6/14.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "MPCommon.h"
#import "MPVPNManager.h"
@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UISwitch *openSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *juhuaView;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    id config = [MPCommon getConfig];
    if (!config) {
        NSLog(@"没有配置");
        return; // 没有配置
    }
    [[MPVPNManager shareInstance] setConfig:config];
    
    [[MPVPNManager shareInstance] saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        NSLog(@"success:%d returnInfo:%@",success, returnInfo);
    }];
    
    self.preferredContentSize = CGSizeMake(self.view.bounds.size.width,40);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.juhuaView.hidden = YES;
    
    [[MPVPNManager shareInstance] mp_NEVPNStatusChanged:^(enum NEVPNStatus status) {
        if (status == NEVPNStatusConnecting) {
            self.juhuaView.hidden = NO;
        }
        else {
            self.juhuaView.hidden = YES;
        }
        [self refreshSwitch];
    }];
    [self refreshSwitch];
}

- (void)refreshSwitch {
    self.openSwitch.on = ([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected);
}
- (IBAction)switchAction:(id)sender {
    if (_openSwitch.on) {
        [[MPVPNManager shareInstance] stop];
    }
    else {
        [[MPVPNManager shareInstance] start];
    }
}

@end
