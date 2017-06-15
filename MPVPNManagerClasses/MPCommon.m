//
//  MPCommon.m
//  MPVPNManager
//
//  Created by mopellet on 2017/6/15.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "MPCommon.h"

@implementation MPCommon
static NSString * const MPAppGroupsName = @"group.com.mopellet.Vpn";
NSString * const kMPVpnConfigKey = @"kMPVpnConfigKey";

+ (NSUserDefaults *)sharedUserDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:MPAppGroupsName];
}

+ (BOOL)saveConfig:(id)config {
    NSUserDefaults *userDefaults = [self sharedUserDefaults];
    NSData * data  = [NSKeyedArchiver archivedDataWithRootObject:config];
    [userDefaults setObject:data forKey:kMPVpnConfigKey];
    return [userDefaults synchronize];
}

+ (id)getConfig {
     NSUserDefaults *userDefaults = [self sharedUserDefaults];
    if ([userDefaults objectForKey:kMPVpnConfigKey]) {
        NSData *data = [userDefaults objectForKey:kMPVpnConfigKey];
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return nil;
}


#pragma mark - KeyChain BEGIN

NSString * const MPVPNPasswordIdentifier = @"MPVPNPasswordIdentifier";
NSString * const MPVPNSharePrivateKeyIdentifier = @"MPVPNSharePrivateKeyIdentifier";

+ (NSString *)getServiceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:[self getServiceName] forKey:(__bridge id)kSecAttrService];
    
    return searchDictionary;
}

+ (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    
    return (__bridge_transfer NSData *)result;
}

+ (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
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
