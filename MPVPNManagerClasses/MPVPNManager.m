
#import "MPVPNManager.h"
#import "AFNetworkReachabilityManager.h"


#pragma mark - 定义一些所需参数 可以替换成自己的 可以上淘宝买一个记得 只支持ipsec
static NSString * const MPVPNPwdIdentifier = @"MPVPNPwdIdentifier"; // 可以自定义
static NSString * const MPVPNPrivateKeyIdentifier = @"MPVPNPrivateKeyIdentifier"; // 可以自定义
static NSString * const MPServiceName = @"com.mopellet.MPVPNManager.MPServiceName"; // 可以自定义

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
{
    _config = config;
    [self createKeychainPassword:_config.password privateKey:_config.privateKey];
}

- (void) createKeychainPassword:(NSString *)password privateKey:(NSString *)privateKey
{
    [self createKeychainValue:password forIdentifier:MPVPNPwdIdentifier];
    [self createKeychainValue:privateKey forIdentifier:MPVPNPrivateKeyIdentifier];
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
    {
        [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
            if (error) {
                completeHandle(NO,[NSString stringWithFormat:@"Load config failed [%@]", error.localizedDescription]);
                return;
            }
            NEVPNProtocolIPSec *p = (NEVPNProtocolIPSec*)_vpnManager.protocol;
            if (!p) {
                p = [[NEVPNProtocolIPSec alloc] init];
            }
            
            p.username = _config.username;
            p.serverAddress = _config.serverAddress;
            p.passwordReference = [self searchKeychainCopyMatching:MPVPNPwdIdentifier];
            p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
            p.sharedSecretReference = [self searchKeychainCopyMatching:MPVPNPrivateKeyIdentifier];
            p.useExtendedAuthentication = YES;
            p.disconnectOnSleep = NO;
            _vpnManager.protocol = p;
            _vpnManager.onDemandEnabled=YES;
            _vpnManager.localizedDescription = _config.configTitle;
            
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



- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:MPServiceName forKey:(__bridge id)kSecAttrService];
    
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

@implementation MPVPNConfig

@end
