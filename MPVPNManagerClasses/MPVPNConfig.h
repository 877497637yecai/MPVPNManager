//
//  MPVPNConfig.h
//  MPVPNManager
//
//  Created by mopellet on 2017/5/31.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>
@interface MPVPNConfig : NSObject
@property (nonatomic, copy) NSString *configTitle;
@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
/** vpn验证证书 p12文件  PKCS12 格式 当前属性与sharePrivateKey 仅有一个有效默认为sharePrivateKey优先*/
@property (nonatomic, copy) NSData *identityData;
/** 证书秘钥 */
@property (nonatomic, copy) NSString *identityDataPassword;
@end
