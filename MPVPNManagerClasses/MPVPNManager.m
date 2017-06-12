
#import "MPVPNManager.h"
#import "AFNetworkReachabilityManager.h"
#import "MPVPNIKEv2Config.h"
#pragma mark - 定义一些所需参数 可以替换成自己的 可以上淘宝买一个记得 只支持ipsec
static NSString * const MPVPNPasswordIdentifier = @"MPVPNPwdIdentifier"; // 可以自定义
static NSString * const MPVPNSharePrivateKeyIdentifier = @"MPVPNPrivateKeyIdentifier"; // 可以自定义
static NSString * const MPServiceName = @"com.mopellet.MPVPNManager.MPServiceName"; // 可以自定义
//static NSString * const MPLocalIdentifier = @"MPLocalIdentifier.client"; // 可以自定义
//static NSString * const MPRemoteIdentifier = @"MPRemoteIdentifier.server"; // 可以自定义

@interface MPVPNManager ()

@property (nonatomic, strong) NEVPNManager * vpnManager;
@property (nonatomic, copy) void (^block)(enum NEVPNStatus status) ;

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
        _vpnManager = [NEVPNManager sharedManager];
        _vpnType = MMPVPNManagerTypeNone;
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

- (void)setConfig:(MPVPNConfig *)config with:(MMPVPNManagerType)vpnType
{

    
    switch (vpnType) {
        case MMPVPNManagerTypeIPSec:
        {
            if (![config isKindOfClass:[MPVPNIPSecConfig class]]) {
                return;
            }
            _config = config;
            _vpnType = MMPVPNManagerTypeIPSec;
            MPVPNIPSecConfig *privateIPSecConfig = (MPVPNIPSecConfig *)_config;
            [self createKeychainPassword:privateIPSecConfig.password privateKey:privateIPSecConfig.sharePrivateKey];
        }
            break;
        case MMPVPNManagerTypeIKEv2:
        {
            if (![config isKindOfClass:[MPVPNIKEv2Config class]]) {
                return;
            }
            _config = config;
             _vpnType = MMPVPNManagerTypeIKEv2;
            MPVPNIKEv2Config *privateIKEv2Config = (MPVPNIKEv2Config *)_config;
            [self createKeychainPassword:privateIKEv2Config.password privateKey:privateIKEv2Config.sharePrivateKey];
        }
            break;
        case MMPVPNManagerTypeNone:
        {
            _config = nil;
            _vpnType = MMPVPNManagerTypeNone;
        }
            break;
    }
   
}

- (void) createKeychainPassword:(NSString *)password privateKey:(NSString *)privateKey
{
//    [self createKeychainValue:password forIdentifier:MPVPNPasswordIdentifier];
//    [self createKeychainValue:privateKey forIdentifier:MPVPNSharePrivateKeyIdentifier];
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
        case MMPVPNManagerTypeIPSec:
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
//                    p.passwordReference = [self searchKeychainCopyMatching:MPVPNPasswordIdentifier];
                    p.passwordReference = privateIPSecConfig.passwordReference;
                    
                    if (
//                        [self searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier] &&
                        privateIPSecConfig.sharePrivateKey) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
//                        p.sharedSecretReference = [self searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier];
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
                        }
                    }];
                }];
            }
            
        }
            break;
        case MMPVPNManagerTypeIKEv2:
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
//                    p.passwordReference = [self searchKeychainCopyMatching:MPVPNPasswordIdentifier];
                    p.passwordReference = privateIKEv2Config.passwordReference;
                    NSString *result = [[NSString alloc] initWithData:p.passwordReference encoding:NSUTF8StringEncoding];
                    NSLog(@"%@",result);
                    
                    p.serverAddress = privateIKEv2Config.serverAddress;
//                    p.serverCertificateIssuerCommonName = @"COMODO RSA Domain Validation Secure Server CA";
                    p.serverCertificateIssuerCommonName = privateIKEv2Config.serverCertificateCommonName;
                    p.serverCertificateCommonName = privateIKEv2Config.serverCertificateCommonName;
                    
                    if (
//                        [self searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier] &&
                        privateIKEv2Config.sharePrivateKey) {
                        p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
//                        p.sharedSecretReference = [self searchKeychainCopyMatching:MPVPNSharePrivateKeyIdentifier];
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
                        }
                    }];
                    
                }];
            }
        }
            break;
        case MMPVPNManagerTypeNone:
            completeHandle(NO,@"please set config or vpn type.");
            break;
    }
    
    
    
}

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
                [self start];
            }
        }
    }];
}
#pragma mark - 自动重连 END


- (void)start{
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
    [_vpnManager.connection stopVPNTunnel];
    NSLog(@"VPN has stopped success");
    [self outPutConnectionStatus];
}

#pragma mark -
#pragma mark - KeyChain BEGIN
//
//
//
//- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
//    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
//    
//    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
//    
//    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
//    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
//    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
//    [searchDictionary setObject:MPServiceName forKey:(__bridge id)kSecAttrService];
//    
//    return searchDictionary;
//}
//
//- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
//    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
//    
//    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
//    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
//    
//    CFTypeRef result = NULL;
//    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
//    
//    return (__bridge_transfer NSData *)result;
//}
//
//- (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
//    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
//    
//    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
//    
//    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
//    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
//    
//    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
//    
//    if (status == errSecSuccess) {
//        return YES;
//    }
//    return NO;
//}
//#pragma mark - KeyChain END

@end
