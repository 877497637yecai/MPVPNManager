//
//  MPVPNConfig.m
//  MPVPNManager
//
//  Created by mopellet on 2017/5/31.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "MPVPNConfig.h"

@implementation MPVPNConfig

- (void)setPassword:(NSString *)password {

    _password = password;
    
    _passwordReference = [password dataUsingEncoding:NSUTF8StringEncoding];
}
@end
