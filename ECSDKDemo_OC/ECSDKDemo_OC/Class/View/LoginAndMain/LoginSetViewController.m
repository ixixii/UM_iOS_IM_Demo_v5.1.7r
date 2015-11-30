//
//  LoginSetViewController.m
//  ECSDKDemo_OC
//
//  Created by jiazy on 15/3/24.
//  Copyright (c) 2015年 ronglian. All rights reserved.
//

#import "LoginSetViewController.h"

@interface LoginSetViewController ()

@end

@implementation LoginSetViewController
{
    UITextField * _serviceIP;
    UITextField * _appKey;
    UITextField * _appToken;
    
    UITextField * _port;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"设置";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem * leftItem = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7){
        leftItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"title_bar_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(returnClicked)];
    }else{
        leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"title_bar_back"] style:UIBarButtonItemStyleDone target:self action:@selector(returnClicked)];
    }
    self.navigationItem.leftBarButtonItem =leftItem;
    
    _serviceIP = [[UITextField alloc] initWithFrame:CGRectMake(30.0f, 74.0f, 160.0f, 30.0f)];
    _serviceIP.borderStyle = UITextBorderStyleLine;
    _serviceIP.placeholder =@"IP地址";
    _serviceIP.text = [DemoGlobalClass sharedInstance].connectorIP;
    [self.view addSubview:_serviceIP];
    
    _port = [[UITextField alloc] initWithFrame:CGRectMake(200.0f, 74.0f, 100.0f, 30.0f)];
    _port.borderStyle = UITextBorderStyleLine;
    _port.placeholder =@"端口";
    _port.text = [DemoGlobalClass sharedInstance].connectorPort;
    [self.view addSubview:_port];
    
    _appKey = [[UITextField alloc]initWithFrame:CGRectMake(30.0f, _serviceIP.frame.origin.y+_serviceIP.frame.size.height+10.0f, 260.0f, 30.0f)];
    _appKey.borderStyle = UITextBorderStyleLine;
    _appKey.placeholder =@"appKey";
    _appKey.text = [DemoGlobalClass sharedInstance].appKey;
    [self.view addSubview:_appKey];
    
    _appToken = [[UITextField alloc]initWithFrame:CGRectMake(30.0f, _appKey.frame.origin.y+_appKey.frame.size.height+10.0f, 260.0f, 30.0f)];
    _appToken.secureTextEntry = YES;
    _appToken.borderStyle = UITextBorderStyleLine;
    _appToken.placeholder =@"appToken";
    _appToken.text = [DemoGlobalClass sharedInstance].appToken;
    [self.view addSubview:_appToken];
    
    UIButton * nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.frame =CGRectMake(10, _appToken.frame.origin.y+_appToken.frame.size.height+15.0f, 300, 45);
    [nextBtn setBackgroundImage:[UIImage imageNamed:@"select_account_button"] forState:UIControlStateNormal];
    [nextBtn setTitle:@"确定" forState:UIControlStateNormal];
    [nextBtn addTarget:self action:@selector(nextBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)returnClicked
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)nextBtnClicked
{
    [DemoGlobalClass sharedInstance].connectorIP = _serviceIP.text;
    [DemoGlobalClass sharedInstance].appKey = _appKey.text;
    [DemoGlobalClass sharedInstance].appToken = _appToken.text;
    [DemoGlobalClass sharedInstance].connectorPort = _port.text;
    
    NSString *loginIp = [DemoGlobalClass sharedInstance].connectorIP;
    NSString *loginPort = [DemoGlobalClass sharedInstance].connectorPort;
    [[ECDevice sharedInstance] setServiceIp:loginIp sport:loginPort.intValue andSoftVersion:kSofeVer];
    
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.detailsLabelText = @"保存成功";
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1.0f];
    
    [self returnClicked];
}
@end
