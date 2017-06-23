//
//  ViewController.m
//  MPVPNManager
//
//  Created by mopellet on 2017/5/30.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "ViewController.h"

#import "MPVPNManager.h"
@interface ViewController()
@property (nonatomic, strong) MPVPNManager * mpVpnManager;
@property (weak, nonatomic) IBOutlet UILabel *describe;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //  https://github.com/MoPellet  更多项目详情点击进入
    // 您的star就是对我开发最大的动力
    
    _mpVpnManager = [MPVPNManager shareInstance];

    /**VPN连接状态的改变**/
    [_mpVpnManager mp_NEVPNStatusChanged:^(enum NEVPNStatus status) {
        [self updateTitle];
    }];
    
    //如果提示vpn服务器并未响应是配置账号的问题 请优先确保账号正确型，可在macOS或者iOS系统自带的VPN测试
    //自行填入正确的账号密码测试
    /*
     * 服务端可以用 strongswan https://www.strongswan.org/
     * 服务端配置可参考 https://raymii.org/s/tags/vpn.html
     */
}


- (void)startIPSec {
    //初始化配置信息
    /**共享秘钥方式*/
    MPVPNIPSecConfig *config = [MPVPNIPSecConfig new];
    config.configTitle = @"MPVPNManager";
    config.serverAddress = @"108.61.180.50";
    config.username = @"chenziqiang01";
    config.password = @"18607114709";
    config.sharePrivateKey = @"tksw123";

    [_mpVpnManager saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        if (success) {
            NSLog(@"config IPSec success");
        }
        else
        {
            NSLog(@"config IPSec error:%@",returnInfo);
        }
    }];
}

- (void)startIKEv2 {
    /**以下方式需要安装pem描述文件*/
    /**不需要验证信息方式*/
    /**直接用AirDrop将CACert.pem发送到手机即可*/
    MPVPNIKEv2Config *config = [MPVPNIKEv2Config new];
    config.configTitle = @"MPVPNManager";
    config.serverAddress = @"serverIP";
    config.username = @"username";
    config.password = @"password";
    config.remoteIdentifier = @"remoteIdentifier";
    config.serverCertificateCommonName = @"StrongSwan Root CA";
    config.serverCertificateIssuerCommonName = @"StrongSwan Root CA";
    _mpVpnManager = [MPVPNManager shareInstance];
    [_mpVpnManager setConfig:config];
    [_mpVpnManager saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        if (success) {
            NSLog(@"config IKEv2 success");
        }
        else
        {
            NSLog(@"config IKEv2 error:%@",returnInfo);
        }
    }];
}

- (void)startL2TPBeta {
    [[MPVPNManager shareInstance] loadL2TPTest];
}

- (void)iOS9Test {
    // ios 9 参考
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
