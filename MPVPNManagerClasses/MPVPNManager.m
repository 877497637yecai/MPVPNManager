
#import "MPVPNManager.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "MPVPNIKEv2Config.h"
//#import "NEVPNProtocolL2TP.h"
#import "MPCommon.h"
#include <dlfcn.h>
//#pragma mark - 定义一些所需参数 可以替换成自己的 可以上淘宝买一个记得 只支持ipsec
//static NSString * const MPVPNPasswordIdentifier = @"MPVPNPasswordIdentifier"; // 可以自定义
//static NSString * const MPVPNSharePrivateKeyIdentifier = @"MPVPNSharePrivateKeyIdentifier"; // 可以自定义

@interface MPVPNManager ()
@property (nonatomic, strong) NEVPNManager * vpnManager;
@end

@implementation MPVPNManager

+ (instancetype)shareInstance
{
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.vpnManager = [NEVPNManager sharedManager];
        _vpnType = MPVPNManagerTypeNone;
        [self performSelector:@selector(registerNetWorkReachability) withObject:nil afterDelay:0.35f];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (enum NEVPNStatus)status{
    return _vpnManager.connection.status;
}

- (void)setConfig:(MPVPNConfig *)config
//             with:(MMPVPNManagerType)vpnType
{
//
//    
//    switch (vpnType) {
//        case MMPVPNManagerTypeIPSec:
//        {
//            if (![config isKindOfClass:[MPVPNIPSecConfig class]]) {
//                return;
//            }
//            _config = config;
//            _vpnType = MMPVPNManagerTypeIPSec;
//            MPVPNIPSecConfig *privateIPSecConfig = (MPVPNIPSecConfig *)_config;
//            [self createKeychainPassword:privateIPSecConfig.password privateKey:privateIPSecConfig.sharePrivateKey];
//        }
//            break;
//        case MMPVPNManagerTypeIKEv2:
//        {
//            if (![config isKindOfClass:[MPVPNIKEv2Config class]]) {
//                return;
//            }
//            _config = config;
//             _vpnType = MMPVPNManagerTypeIKEv2;
//            MPVPNIKEv2Config *privateIKEv2Config = (MPVPNIKEv2Config *)_config;
//            [self createKeychainPassword:privateIKEv2Config.password privateKey:privateIKEv2Config.sharePrivateKey];
//        }
//            break;
//        case MMPVPNManagerTypeNone:
//        {
//            _config = nil;
//            _vpnType = MMPVPNManagerTypeNone;
//        }
//            break;
//    }
    
    
    if ([config isKindOfClass:[MPVPNIPSecConfig class]]) {
        _config = config;
        _vpnType = MPVPNManagerTypeIPSec;
        MPVPNIPSecConfig *privateIPSecConfig = (MPVPNIPSecConfig *)_config;
        [self createKeychainPassword:privateIPSecConfig.password privateKey:privateIPSecConfig.sharePrivateKey];
    }
    else if ([config isKindOfClass:[MPVPNIKEv2Config class]]){
        _config = config;
        _vpnType = MPVPNManagerTypeIKEv2;
        MPVPNIKEv2Config *privateIKEv2Config = (MPVPNIKEv2Config *)_config;
        [self createKeychainPassword:privateIKEv2Config.password privateKey:privateIKEv2Config.sharePrivateKey];
    }
    else {
        _config = nil;
        _vpnType = MPVPNManagerTypeNone;
    }
   
}

- (void) createKeychainPassword:(NSString *)password privateKey:(NSString *)privateKey
{
    if (password.length) {
         [MPCommon createKeychainValue:password forIdentifier:MPVPNPasswordIdentifier];
    }
   
    if (privateKey.length) {
        [MPCommon createKeychainValue:privateKey forIdentifier:MPVPNSharePrivateKeyIdentifier];
    }
   
}

- (void) saveConfigCompleteHandle:(CompleteHandle)completeHandle;{
    if (!_vpnManager) {
        completeHandle(NO,@"NEVPNManager Uninitialized");
        return;
    }
    
    if (!_config) {
        completeHandle(NO,@"Configuration parameters cannot be empty");
        return;
    }
    
    //  这里才是核心代码 仅支持 ipsec
    // 1. 获取NEVPNManager实例
    // 2. loadFromPreferencesWithCompletionHandler 加载设置
    // 3. saveToPreferencesWithCompletionHandler 设置并存储设置
    switch (_vpnType) {
        case MPVPNManagerTypeIPSec:
        {
            {
                [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
                    if (error) {
                        completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                        return;
                    }
                    MPVPNIPSecConfig *privateIPSecConfig = (MPVPNIPSecConfig *)_config;
                    NEVPNProtocolIPSec *p = (NEVPNProtocolIPSec*)_vpnManager.protocol;
                    if (!p) {
                        p = [[NEVPNProtocolIPSec alloc] init];
                    }
                    
                    p.username = privateIPSecConfig.username;
                    p.serverAddress = privateIPSecConfig.serverAddress;
                    p.passwordReference = [MPCommon searchKeychainCopyMatching:MPVPNPasswordIdentifier];
                    
                    if (
                        [MPCommon searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier] &&
                        privateIPSecConfig.sharePrivateKey) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
                        p.sharedSecretReference = [MPCommon searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier];
                    }
                    else if (privateIPSecConfig.identityData && privateIPSecConfig.password) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodCertificate;
                        p.identityData = privateIPSecConfig.identityData;
                        p.identityDataPassword = privateIPSecConfig.identityDataPassword;
                    }
                    else{
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodNone;
                    }
                    
                    p.localIdentifier = privateIPSecConfig.localIdentifier;
                    p.remoteIdentifier = privateIPSecConfig.remoteIdentifier;
                    p.useExtendedAuthentication = YES;
                    p.disconnectOnSleep = NO;
                    
                    _vpnManager.protocol = p;
                    _vpnManager.onDemandEnabled = YES;
                    _vpnManager.localizedDescription = privateIPSecConfig.configTitle;
                    _vpnManager.enabled = YES;
                    
                    // 保存设置
                    [_vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                        if(error) {
                            completeHandle(NO,[NSString stringWithFormat:@"Save config failed [%@]", error.localizedDescription]);
                        }
                        else {
                            completeHandle(YES,@"Save config success");
//                            [MPCommon sharedUserDefaults] setObject:<#(nullable id)#> forKey:@"MP"
                            [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                                if (error) {
                                    completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                                    return;
                                }
                            }];
                        }
                    }];
                }];
            }
            
        }
            break;
        case MPVPNManagerTypeIKEv2:
        {
            {
                [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                        return;
                    }
                    
                    MPVPNIKEv2Config *privateIKEv2Config = (MPVPNIKEv2Config *)_config;
                    
                    NEVPNProtocolIKEv2 *p = [NEVPNProtocolIKEv2 new];
                    p.username = privateIKEv2Config.username;
                    p.passwordReference = [MPCommon searchKeychainCopyMatching:MPVPNPasswordIdentifier];
                    
                    p.serverAddress = privateIKEv2Config.serverAddress;
                    p.serverCertificateIssuerCommonName = privateIKEv2Config.serverCertificateCommonName;
                    p.serverCertificateCommonName = privateIKEv2Config.serverCertificateCommonName;
                    
                    if (
                        [MPCommon searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier] &&
                        privateIKEv2Config.sharePrivateKey) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
                        p.sharedSecretReference = [MPCommon searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier];
                    }
                    else if (privateIKEv2Config.identityData && privateIKEv2Config.password) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodCertificate;
                        p.identityData = privateIKEv2Config.identityData;
                        p.identityDataPassword = privateIKEv2Config.identityDataPassword;
                    }
                    else{
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodNone;
                    }
                    
//                    p.identityData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"point-to-client2" ofType:@"p12"]];
//                    p.identityDataPassword = @"vpnuser";
                    
                    p.localIdentifier = privateIKEv2Config.localIdentifier;
                    p.remoteIdentifier = privateIKEv2Config.remoteIdentifier;
                    p.useExtendedAuthentication = YES;
                    p.disconnectOnSleep = NO;
                    
                    [_vpnManager setProtocol:p];
                    [_vpnManager setOnDemandEnabled:YES];
                    [_vpnManager setEnabled:YES];
                    
//                    NEEvaluateConnectionRule * ru = [[NEEvaluateConnectionRule alloc]
//                                                     initWithMatchDomains:@[@"google.com"]
//                                                     andAction:NEEvaluateConnectionRuleActionConnectIfNeeded];
//                    
//                    ru.probeURL = [[NSURL alloc] initWithString:@"http://www.google.com"];
//                    
//                    NEOnDemandRuleEvaluateConnection *ec =[[NEOnDemandRuleEvaluateConnection alloc] init];
//                    //                ec.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi;
//                    [ec setConnectionRules:@[ru]];
//                    [_vpnManager setOnDemandRules:@[ec]];
                    
                    [_vpnManager setLocalizedDescription:privateIKEv2Config.configTitle];
                    [_vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                        if(error) {
                            completeHandle(NO,[NSString stringWithFormat:@"Save config failed [%@]", error.localizedDescription]);
                        }
                        else {
                            completeHandle(YES,@"Save config success");
                            [MPCommon saveConfig:_config];
                            id conf = [MPCommon getConfig];
                            NSLog(@"%@", [conf class]);
                            [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                                if (error) {
                                    completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                                    return;
                                }
                            }];
                        }
                    }];
                    
                }];
            }
        }
            break;
        case MPVPNManagerTypeNone:
            completeHandle(NO,@"please set config or vpn type.");
            break;
        case MPVPNManagerTypeL2TP:
            // see loadL2TPTest;
            break;
    }
    
}


- (void)loadL2TPTest{
    NSBundle *b = [NSBundle bundleWithPath:@"/System/Library/Frameworks/NetworkExtension.framework"];
    BOOL success = [b load];
    //    Class NEVPNProtocolL2TP = NSClassFromString(@"NEVPNProtocolL2TP");
    void *lib = dlopen("/System/Library/Frameworks/NetworkExtension.framework", RTLD_LAZY);
    if(success) {
        [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            
            Class NEVPNProtocolL2TP = NSClassFromString(@"NEVPNProtocolL2TP");
            if (NEVPNProtocolL2TP) {
                NSLog(@"找到当前类");
            }
//            NEVPNProtocolL2TP *p = [[NEVPNProtocolL2TP alloc] init];
            NEVPNProtocol *p = [[NEVPNProtocolL2TP alloc] init];
            
            p.username = @"ZEE";
            [MPCommon createKeychainValue:@"ZEE" forIdentifier:@"L2TPPWD"];
            p.passwordReference = [MPCommon searchKeychainCopyMatching:@"L2TPPWD"];
            p.serverAddress = @"47.91.167.23";
            [MPCommon createKeychainValue:@"vpn" forIdentifier:@"L2TPSS"];
//            p.sharedSecretReference = [MPCommon searchKeychainCopyMatching:@"L2TPSS"];
            
            [p performSelector:@selector(setSharedSecretReference:) withObject:[MPCommon searchKeychainCopyMatching:@"L2TPSS"]];
            p.disconnectOnSleep = NO;
            
            [NEVPNManager sharedManager].protocol = p;
            [NEVPNManager sharedManager].onDemandEnabled = YES;
            [NEVPNManager sharedManager].localizedDescription = @"L2TP";
            [NEVPNManager sharedManager].enabled = YES;
           
//            NEVPNProtocol * rp = [[NEVPNManager sharedManager] protocolConfiguration];
//           BOOL hav = [[NEVPNManager sharedManager] respondsToSelector:@selector(isProtocolTypeValid:)];
//           BOOL hav1 = [rp respondsToSelector:@selector(type)];
//            if (hav1) {
////                [rp performSelector:@selector(type)];
////                rp 
////                NSMethodSignature *signature = [rp instanceMethodSignatureForSelector:@selector(type)];
////                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
////                invocation.target = rp;
////                invocation.selector = @selector(type);
//            }
//            id a = [rp performSelector:@selector(type)];
            
            NSLog(@"ok");
            
            [ [NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *error) {
                if(error) {
                    NSLog(@"Save config failed:%@",error);
//                    completeHandle(NO,[NSString stringWithFormat:@"Save config failed [%@]", error.localizedDescription]);
                }
                else {
                    NSLog(@"Save config success");
                    [ [NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"re Save config failed:%@",error);
//                            completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                            return;
                        }
                    }];
                }
            }];
        }];
    }
    
}



#pragma mark -
#pragma mark - 自动重连 BEGIN
- (void)registerNetWorkReachability{
//    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
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
                [self start];
            }
        }
    }];
}
#pragma mark - 自动重连 END
- (void)start{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    NSError *startError;
    [_vpnManager.connection startVPNTunnelAndReturnError:&startError];
    if (startError) {
        NSLog(@"Start VPN failed: [%@]", startError.localizedDescription);
    }
    [self outPutConnectionStatus];
}

- (void)outPutConnectionStatus{
    switch (_vpnManager.connection.status) {
        case NEVPNStatusInvalid:
            NSLog(@"NEVPNStatusInvalid The VPN is not configured.");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"NEVPNStatusDisconnected The VPN is disconnected.");
            break;
        case NEVPNStatusConnecting:
            NSLog(@"NEVPNStatusConnecting The VPN is connecting.");
            break;
        case NEVPNStatusConnected:
            NSLog(@"NEVPNStatusConnected The VPN is connected.");
            break;
        case NEVPNStatusReasserting:
            NSLog(@"NEVPNStatusReasserting The VPN is reconnecting following loss of underlying network connectivity.");
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"NEVPNStatusDisconnecting The VPN is disconnecting.");
            break;
        default:
            break;
    }
}

- (void)stop{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [_vpnManager.connection stopVPNTunnel];
    NSLog(@"VPN has stopped success");
    [self outPutConnectionStatus];
}


- (void)mp_NEVPNStatusChanged:(StatusChanged)statusChanged
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification
                                                      object:self.vpnManager.connection
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        statusChanged(self.vpnManager.connection.status);
    }];
}

@end
