//
//  TodayViewController.m
//  MPWidget
//
//  Created by mopellet on 2017/6/14.
//  Copyright © 2017年 mopellet. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    NSUserDefaults* userDefault = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.mopellet.Vpn"];
//    NSString* nickName = [userDefault objectForKey:@"nickname"];
//    NSLog(@"%@",nickName);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (IBAction)switchAction:(id)sender {
    
}

@end
