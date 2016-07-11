//
//  ViewController.m
//  VpnTest
//
//  Created by Pellet Mo on 15/12/14.
//  Copyright © 2015年 mopellet. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>
#import "AFNetworkReachabilityManager.h"





#pragma mark - 定义一些所需参数 可以替换成自己的 可以上淘宝买一个记得 只支持ipsec
#define server @"108.61.180.50"
#define ID @"chenziqiang01"
#define pwd @"18607114709"
#define privateKey @"tksw123"

@interface ViewController ()
@property(strong,nonatomic)NEVPNManager *vpnManager;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
}

- (void)setUp{
    // 将账号密码存入钥匙串
    {
        [self createKeychainValue:pwd forIdentifier:@"vpnPassWord"];
        [self createKeychainValue:privateKey forIdentifier:@"sharedKey"];
    }
    
    //  这里才是核心代码 仅支持 ipsec 
    // 1. 获取NEVPNManager实例
    // 2. loadFromPreferencesWithCompletionHandler 加载设置
    // 3. saveToPreferencesWithCompletionHandler 设置并存储设置
    {
        self.vpnManager = [NEVPNManager sharedManager];
        [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Load config failed [%@]", error.localizedDescription);
                return;
            }
            NEVPNProtocolIPSec *p = (NEVPNProtocolIPSec*)_vpnManager.protocol;
            if (!p) {
                p = [[NEVPNProtocolIPSec alloc] init];
            }
            
            p.username = ID;
            p.serverAddress = server;
            p.passwordReference = [self searchKeychainCopyMatching:@"vpnPassWord"];
            p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
            p.sharedSecretReference = [self searchKeychainCopyMatching:@"sharedKey"];
            p.useExtendedAuthentication = YES;
            p.disconnectOnSleep = NO;
            _vpnManager.protocol = p;
            _vpnManager.onDemandEnabled=YES;
            _vpnManager.localizedDescription = @"IPSec Test"; //设置VPN的名字 可以自定义
            
            // 一定要保存
            [_vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                if(error) {
                    NSLog(@"Save error: %@", error);
                }
                else {
                    NSLog(@"Saved!");
                }
            }];
        }];
    }
    
    
    //检测网络 自动重连 （可选）
    [self performSelector:@selector(registerNetWorkReachability) withObject:nil afterDelay:0.35f];
}


#pragma mark -
#pragma mark - 操作方法 BEGIN
- (IBAction)buttonPressed:(id)sender {
    [self vpnStart];
}

- (IBAction)buttonStop:(id)sender {
    [self vpnStop];
}

-(void)vpnStart{
    NSError *startError;
    [_vpnManager.connection startVPNTunnelAndReturnError:&startError];
    if (startError) {
        NSLog(@"Start VPN failed: [%@]", startError.localizedDescription);
    }
}

-(void)vpnStop{
    [_vpnManager.connection stopVPNTunnel];
}
#pragma mark - 操作方法 END

#pragma mark -
#pragma mark - 自动重连 BEGIN
- (void)registerNetWorkReachability{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetWork) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
}
/**
 *  检测网络
 */
-(void)checkNetWork{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusReachableViaWWAN ||
            status == AFNetworkReachabilityStatusReachableViaWiFi) {
            if (self.vpnManager.connection.status != NEVPNStatusConnected) {
                [self vpnStart];
            }
        }
    }];
}
#pragma mark - 自动重连 END



#pragma mark -
#pragma mark - KeyChain BEGIN

static NSString * const serviceName = @"im.zorro.ipsec_demo.vpn_config"; // 可以自定义

- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    
    return searchDictionary;
}

- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    
    return (__bridge_transfer NSData *)result;
}

- (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}
#pragma mark - KeyChain END

@end
