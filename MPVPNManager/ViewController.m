//
//  ViewController.m
//  MPVPNManager
//
//  Created by mopellet on 2017/5/30.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "ViewController.h"

#import "MPVPNManager.h"

#import <SAMKeychain/SAMKeychain.h>
@interface ViewController()
@property (nonatomic, strong) MPVPNManager * mpVpnManager;
@property (weak, nonatomic) IBOutlet UILabel *describe;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //  https://github.com/MoPellet  更多项目详情点击进入
    // 您的star就是对我开发最大的动力
    
    //初始化配置信息
    /**共享秘钥方式*/
//    MPVPNIPSecConfig *config = [MPVPNIPSecConfig new];
//    config.configTitle = @"MPVPNManager";
//    config.serverAddress = @"108.61.180.50";
//    config.username = @"chenziqiang01";
//    config.password = @"18607114709";
//    config.sharePrivateKey = @"tksw123";
//    
//    _mpVpnManager = [MPVPNManager shareInstance];
//    [_mpVpnManager setConfig:config with:MMPVPNManagerTypeIPSec];
//    [_mpVpnManager saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
//        NSLog(@"returnInfo:%@",returnInfo);
//        if (success) {
//            [self start:nil];
//        }
//    }];
//
    
    
    /**以下方式需要安装pem描述文件*/
    /**不需要验证信息方式*/
    /**直接用AirDrop将CACert.pem发送到手机即可*/
    MPVPNIKEv2Config *config = [MPVPNIKEv2Config new];
    config.configTitle = @"MPVPNManager";
    config.serverAddress = @"64.62.228.225";
    config.username = @"roland";
    config.password = @"roland";
    config.remoteIdentifier = @"cafre.funkernel.com";
    config.serverCertificateCommonName = @"StrongSwan Root CA";
    config.serverCertificateIssuerCommonName = @"StrongSwan Root CA";
    _mpVpnManager = [MPVPNManager shareInstance];
    [_mpVpnManager setConfig:config with:MMPVPNManagerTypeIKEv2];
    [_mpVpnManager saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        NSLog(@"returnInfo:%@",returnInfo);
        if (success) {
            [self start:nil];
        }
    }];
    
    // 如果提示vpn服务器并未响应是配置账号的问题 请使用正确的账号设置MPVPNConfig即可
    
    //    // ios 9 参考
    //    {
    //        NETunnelProviderManager * manager = [[NETunnelProviderManager alloc] init];
    //        NETunnelProviderProtocol * protocol = [[NETunnelProviderProtocol alloc] init];
    //        protocol.providerBundleIdentifier = @"com.mopellet.Vpn";
    //
    //        protocol.providerConfiguration = @{@"key":@"value"};
    //        protocol.serverAddress = @"server";
    //        manager.protocolConfiguration = protocol;
    //        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
    //
    //        }];
    //
    //        NETunnelProviderSession * session = (NETunnelProviderSession *)manager.connection;
    //        NSDictionary * options = @{@"key" : @"value"};
    //
    //        NSError * err;
    //        [session startTunnelWithOptions:options andReturnError:&err];
    //
    //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //            NSLog(@"%ld",(long)manager.connection.status);
    //        });
    //    }
    
    // 监听状态
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTitle) userInfo:self repeats:YES];
}

- (IBAction)start:(id)sender {
    [_mpVpnManager start];
}

- (IBAction)stop:(id)sender {
    [_mpVpnManager stop];
}

- (void)updateTitle{
    NSString * string = @"Invalid";
    switch (_mpVpnManager.status) {
        case NEVPNStatusInvalid:
            string = @"Invalid";
            break;
        case NEVPNStatusDisconnected:
            string = @"Disconnected";
            break;
        case NEVPNStatusConnecting:
            string = @"Connecting";
            break;
        case NEVPNStatusConnected:
            string = @"Connected";
            break;
        case NEVPNStatusReasserting:
            string = @"Reasserting";
            break;
        case NEVPNStatusDisconnecting:
            string = @"Disconnecting";
            break;
    }
    _describe.text = string;
}

@end
