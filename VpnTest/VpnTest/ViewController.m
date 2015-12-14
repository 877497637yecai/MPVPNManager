//
//  ViewController.m
//  VpnTest
//
//  Created by Pellet Mo on 15/12/14.
//  Copyright © 2015年 mopellet. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>
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
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self createKeychainValue:pwd forIdentifier:@"vpnPassWord"];
    [self createKeychainValue:privateKey forIdentifier:@"sharedKey"];
   
    [self setUp];
}

-(void)setUp{
    self.vpnManager = [NEVPNManager sharedManager];

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

- (IBAction)buttonPressed:(id)sender {
    NSError *startError;
    [_vpnManager.connection startVPNTunnelAndReturnError:&startError];
    if (startError) {
        NSLog(@"Start VPN failed: [%@]", startError.localizedDescription);
    }
    
}

- (IBAction)buttonStop:(id)sender {
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
