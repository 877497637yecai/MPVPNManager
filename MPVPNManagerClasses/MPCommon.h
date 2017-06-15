//
//  MPCommon.h
//  MPVPNManager
//
//  Created by mopellet on 2017/6/15.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPCommon : NSObject

extern NSString * const kMPVpnConfigKey;

+ (NSUserDefaults *)sharedUserDefaults;

+ (BOOL)saveConfig:(id)config;

+ (id)getConfig;


extern NSString * const MPVPNPasswordIdentifier;
extern NSString * const MPVPNSharePrivateKeyIdentifier;

+ (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier;

+ (NSData *)searchKeychainCopyMatching:(NSString *)identifier;

@end
