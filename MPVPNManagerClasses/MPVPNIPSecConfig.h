//
//  MPVPNIPSecConfig.h
//  MPVPNManager
//
//  Created by mopellet on 2017/5/31.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "MPVPNConfig.h"

@interface MPVPNIPSecConfig : MPVPNConfig
/** 共享秘钥 */
@property (nonatomic, copy, nullable) NSString *sharePrivateKey;
@property (nonatomic, copy, nullable) NSString *localIdentifier;
@property (nonatomic, copy, nullable) NSString *remoteIdentifier;
@end
