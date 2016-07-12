//
//  ViewController.m
//  VpnTest
//
//  Created by Pellet Mo on 15/12/14.
//  Copyright © 2015年 mopellet. All rights reserved.
//

#import "ViewController.h"
#import "MoVPNManage.h"
#import <NetworkExtension/NetworkExtension.h>
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
    
    
    
    // ios 9 参考
    {
        NETunnelProviderManager * manager = [[NETunnelProviderManager alloc] init];
        NETunnelProviderProtocol * protocol = [[NETunnelProviderProtocol alloc] init];
        protocol.providerBundleIdentifier = @"com.mopellet.Vpn";
        
        protocol.providerConfiguration = @{@"key":@"value"};
        protocol.serverAddress = @"server";
        manager.protocolConfiguration = protocol;
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            
        }];
        
        NETunnelProviderSession * session = (NETunnelProviderSession *)manager.connection;
        NSDictionary * options = @{@"key" : @"value"};
        
        NSError * err;
        [session startTunnelWithOptions:options andReturnError:&err];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"%ld",(long)manager.connection.status);
        });
    }
    
}

#pragma mark - 操作方法 BEGIN
- (IBAction)buttonPressed:(id)sender {
    [[MoVPNManage shareVPNManage] vpnStart];
}
- (IBAction)buttonStop:(id)sender {
    [[MoVPNManage shareVPNManage] vpnStop];
}

@end
