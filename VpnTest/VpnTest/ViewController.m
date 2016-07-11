//
//  ViewController.m
//  VpnTest
//
//  Created by Pellet Mo on 15/12/14.
//  Copyright © 2015年 mopellet. All rights reserved.
//

#import "ViewController.h"
#import "MoVPNManage.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MoVPNManage * vpnManage = [MoVPNManage shareVPNManage];
    [vpnManage setVpnTitle:@"Happy Vpn"];
    [vpnManage setServer:@"108.61.180.50" ID:@"chenziqiang01" pwd:@"18607114709" privateKey:@"tksw123"];
    [vpnManage setReconnect:YES];
    [vpnManage saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        NSLog(@"%@",returnInfo);
        if (success) {
            [vpnManage vpnStart];
        }
    }];
}

#pragma mark - 操作方法 BEGIN
- (IBAction)buttonPressed:(id)sender {
    [[MoVPNManage shareVPNManage] vpnStart];
}
- (IBAction)buttonStop:(id)sender {
    [[MoVPNManage shareVPNManage] vpnStop];
}

@end
