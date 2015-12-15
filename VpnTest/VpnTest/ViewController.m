//
//  ViewController.m
//  VpnTest
//
//  Created by Pellet Mo on 15/12/14.
//  Copyright © 2015年 mopellet. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>
#import "Reachability.h"
#define server @"108.61.180.50"
#define ID @"chenziqiang01"
#define pwd @"18607114709"
#define privateKey @"tksw123"
//    vpn 选择 ipsec
//    描述 随便写
//    服务器：108.61.180.50
//    账号 ：chenziqiang01
//    密码：18607114709
//    秘钥：tksw123
@interface ViewController ()
@property(strong,nonatomic)NEVPNManager *vpnManager;
@property (nonatomic, strong) Reachability *conn;
@property (nonatomic,assign) BOOL checkVPN;//检查VPN断线重连
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
}

-(void)setUp{
    self.checkVPN = YES;
    [self createKeychainValue:pwd forIdentifier:@"vpnPassWord"];
    [self createKeychainValue:privateKey forIdentifier:@"sharedKey"];
    self.vpnManager = [NEVPNManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    self.conn = [Reachability reachabilityForInternetConnection];
    [self.conn startNotifier];
    
    
    [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Load config failed [%@]", error.localizedDescription);
            return;
        }
        
        NEVPNProtocolIPSec *p = (NEVPNProtocolIPSec*)_vpnManager.protocol;
        
        if (p) {
            
        } else {
            
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
        _vpnManager.localizedDescription = @"IPSec Test";
        
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
- (void)networkStateChange
{
    [self checkNetworkState];
}

- (void)checkNetworkState
{
    // 1.检测wifi状态
    Reachability *wifi = [Reachability reachabilityForLocalWiFi];
    
    // 2.检测手机是否能上网络(WIFI\3G\2.5G)
    Reachability *conn = [Reachability reachabilityForInternetConnection];
    
    // 3.判断网络状态
    if ([wifi currentReachabilityStatus] != NotReachable) { // 有wifi
        NSLog(@"有wifi");
        [self checkVpn];
    } else if ([conn currentReachabilityStatus] != NotReachable) { // 没有使用wifi, 使用手机自带网络进行上网
        NSLog(@"使用手机自带网络进行上网");
        [self checkVPN];
    } else { // 没有网络
        NSLog(@"没有网络");
        [self vpnStop];
    }
}

-(void)checkVpn{
    if (self.checkVPN==YES) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.vpnManager.connection.status!=3) {
                [self vpnStart];
            }
        });
    }
}

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

#pragma mark - KeyChain

static NSString * const serviceName = @"im.zorro.ipsec_demo.vpn_config";

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
    
    // Add search attributes
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Add search return types
    // Must be persistent ref !!!!
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
@end
