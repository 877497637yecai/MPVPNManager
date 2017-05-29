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

typedef void(^CompleteHandle)(BOOL success , NSString * returnInfo);
typedef void(^StatusChanged)(enum NEVPNStatus status);
typedef NS_ENUM(NSInteger, MPVPNManagerStatus){
    MPVPNManagerStatusUnknow,
    MPVPNManagerStatusRunning,
    MPVPNManagerStatusStop
};

@class MPVPNConfig;
@interface MPVPNManager : NSObject

+ (instancetype)shareInstance;
/** config info */
@property (nonatomic, strong) MPVPNConfig *config;
/** run status */
@property (nonatomic, readonly, assign) enum NEVPNStatus status;
/** save config */
- (void)saveConfigCompleteHandle:(CompleteHandle)completeHandle;

- (void)start;
- (void)stop;

@end

@interface MPVPNConfig : NSObject
@property (nonatomic, copy) NSString *configTitle;
@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *privateKey;
@end






