//
//  MPVPNIKEv2Config.h
//  MPVPNManager
//
//  Created by mopellet on 2017/5/31.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "MPVPNIPSecConfig.h"

@interface MPVPNIKEv2Config : MPVPNIPSecConfig
@property (copy, nullable) NSString *serverCertificateIssuerCommonName;
@property (copy, nullable) NSString *serverCertificateCommonName;
@end
