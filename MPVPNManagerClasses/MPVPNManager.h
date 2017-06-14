//
//  ViewController.h
//  MPVPNManager
//
//  Created by mopellet on 2017/5/30.
//  Copyright © 2017年 mopellet. All rights reserved.
//

/*
 * 仅支持IPSEC协议
 * 更多项目请进入 本人github:https://github.com/MoPellet
 */

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import "MPVPNIKEv2Config.h"

typedef void(^CompleteHandle)(BOOL success , NSString * returnInfo);
typedef void(^StatusChanged)(enum NEVPNStatus status);

typedef NS_ENUM(NSInteger, MMPVPNManagerType){
    MMPVPNManagerTypeNone,
    MMPVPNManagerTypeIPSec,
    MMPVPNManagerTypeIKEv2,
};

@class MPVPNConfig;
@interface MPVPNManager : NSObject

+ (instancetype)shareInstance;
/** config info */
@property (nonatomic, readonly, strong) MPVPNConfig *config;
@property (nonatomic, readonly, assign) MMPVPNManagerType vpnType;

- (void)setConfig:(MPVPNConfig *)config with:(MMPVPNManagerType)vpnType;
/** run status */
@property (nonatomic, readonly, assign) enum NEVPNStatus status;
/** save config */
- (void)saveConfigCompleteHandle:(CompleteHandle)completeHandle;

- (void)start;
- (void)stop;

- (void)mp_NEVPNStatusChanged:(StatusChanged)statusChanged;

- (void)loadL2TPTest;
@end

