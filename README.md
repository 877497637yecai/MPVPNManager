# MPVPNManager
iOS VPN 支持IPSec IKEv2 协议 三步启动 轻松畅玩

## Description 描述
* 支持iOS8以上的vpn 暂时支持PSec IKEv2协议
* 支持断线重连
* 此项目不定期更新，有问题发Issues，我会尽力解决。
* 可以Watch该项目，watch之后项目更新你会收实时收到通知。
* 最后star一下，多谢各位老铁们。

## 更新日志 
### 2017年06月13更新 
* 增加pod支持，加入‘SAMKeychain’，‘AFNetworking’
* 修复获取钥匙串的值不正确的bug
* 优化部分代码
### 2017年05月31更新 
* 增加IKEv2支持
* 重写部分接口代码
### 2017年05月30更新 
* 重写大部分源码增加可读性
* 修复断线重连的bug


## Usage 使用方法
* 1、将子文件夹MPVPNManagerClasses拖入到项目中。
* 2、将MPConfig.entitlements加入到Project->Target->Build Settings->Code Signing Entitlements
* 3、如果已经有其它的entitlements，将MPConfig.entitlements中的value加入到你的entitlements文件即可
* 4、导入MPVPNManager.h文件 

```objc
    #import "MPVPNManager.h"
```

* 5、初始化配置信息并启动

```objc
	//初始化配置
    MPVPNConfig *config = [MPVPNConfig new];
    config.configTitle = @"MPVPNManager"; // 显示在系统设置VPN的标题
    config.serverAddress = @"108.61.180.50"; // VPN地址
    config.username = @"chenziqiang01";
    config.password = @"18607114709";
    config.privateKey = @"tksw123";
    
    MPVPNManager *mpVpnManager = [MPVPNManager shareInstance];
    // 添加配置信息
    mpVpnManager.config = config;
    // 保存配置信息
    [mpVpnManager saveConfigCompleteHandle:^(BOOL success, NSString *returnInfo) {
        if (success) {
        		//开始运行
             [mpVpnManager start];
        }
    }];
    
```

## 注意
* 如果提示vpn服务器并未响应是配置账号的问题 请使用正确的账号设置MPVPNConfig即可


## 相关资料
* [Configure and manage VPN connections programmatically in iOS 8](http://ramezanpour.net/post/2014/08/03/configure-and-manage-vpn-connections-programmatically-in-ios-8/)
    

## 联系方式:
* WeChat : wzw351420450
* Email : mopellet@foxmail.com
* Resume : [个人简历](https://github.com/MoPellet/Resume)

## 特别鸣谢:
* 您的star的我开发的动力，如果代码对您有帮助麻烦动动您的小手指点个start。

