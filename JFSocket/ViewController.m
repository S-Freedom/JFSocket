//
//  ViewController.m
//  JFSocket
//
//  Created by huangpengfei on 2018/5/25.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"
#import "JFPerson.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <Social/Social.h>



#define USERNAME @"username"
#define USERID @"userID"
#define PWD @"pwd"
#define maxReConnectCount 10
#define  ScreenW  [UIScreen mainScreen].bounds.size.width
#define  ScreenH  [UIScreen mainScreen].bounds.size.height

@interface ViewController () <AsyncSocketDelegate>
@property (nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UITextField *toTextField;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITextView *textView;

@property(nonatomic, copy) NSString *myName;
@property(nonatomic, copy) NSString *pwd;
@property(nonatomic, copy) JFPerson *person;
@property(nonatomic, strong) AsyncSocket *socket;
@property(nonatomic, assign) BOOL isOnline;
@property(nonatomic, strong) UILabel *selfLabel;
@property(nonatomic, assign) BOOL isReConnect;
@property(nonatomic, assign) long reConnectCount;

@property(nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadUI];
    self.reConnectCount = 0;
}

- (void)timerFun{
    [self sendKeepAlive];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.textField resignFirstResponder];
}

- (void)loadUI{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 100, 50)];
    [btn setTitle:@"login" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(loginBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *lineServer = [[UIButton alloc] initWithFrame:CGRectMake(130, 10, 100, 50)];
    [lineServer setTitle:@"line server" forState:UIControlStateNormal];
    [lineServer setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [lineServer addTarget:self action:@selector(lineServerBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lineServer];
    
    UILabel *selfLabel = [[UILabel alloc] initWithFrame:CGRectMake(260, 10, 100, 50)];
    selfLabel.textColor = [UIColor blackColor];
    selfLabel.font = [UIFont systemFontOfSize:14.0f];
    self.selfLabel = selfLabel;
    [self.view addSubview:selfLabel];
    
    self.dataArr = [NSMutableArray arrayWithCapacity:20];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 64, ScreenW - 20, 50)];
    textField.layer.borderColor = [UIColor blackColor].CGColor;
    textField.layer.borderWidth = 0.5f;
    textField.placeholder = @"input message to send";
    self.textField = textField;
    [self.view addSubview:textField];
    
    UITextField *toTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 124, ScreenW - 20, 50)];
    toTextField.layer.borderColor = [UIColor blackColor].CGColor;
    toTextField.layer.borderWidth = 0.5f;
    toTextField.placeholder = @"your friends's username";
    self.toTextField = toTextField;
    [self.view addSubview:toTextField];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 200, ScreenW - 20, ScreenH - 200 - 50 - 20)];
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont systemFontOfSize:14.0f];
    textView.layer.borderWidth = 0.5f;
    textView.layer.borderColor = [UIColor blackColor].CGColor;
    textView.userInteractionEnabled = NO;
    self.textView = textView;
    [self.view addSubview:textView];
    
    UIButton *sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, ScreenH - 50, ScreenW, 50)];
    [sendBtn setTitle:@"send" forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
}


- (void)loginBtnClick{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"title" message:@"input your message" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"input your username";
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"input your pwd";
        textField.secureTextEntry = YES;
    }];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"login" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *username = alertController.textFields.firstObject.text;
        NSString *pwd = alertController.textFields.lastObject.text;
        if(username != nil && pwd != nil){
            weakSelf.person = [[JFPerson alloc] initName:username pwd:pwd];
            
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:username forKey:USERNAME];
            [userDefault setInteger:weakSelf.person.userID forKey:USERID];
            [userDefault setObject:pwd forKey:PWD];
            [userDefault synchronize];
            [weakSelf lineServerBtnClick];
            weakSelf.selfLabel.text = [NSString stringWithFormat:@"Hi: %@",username];
            NSLog(@"%@,%@",username,pwd);
        }else{
            NSLog(@"username or pwd is nil");
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:^{
        
    }];
}


#pragma mark JFSOCKET
- (void)lineServerBtnClick{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *name = [userDefault objectForKey:USERNAME];
    NSString *pwd = [userDefault objectForKey:PWD];
    
    if(name == nil || pwd == nil || USERID == nil){
        [self loginBtnClick];
        return;
    }
    JFPerson *person = [[JFPerson alloc] initName:name pwd:pwd];
    self.person = [person copy];
    [self.socket disconnect];
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    NSError *error;
    @try {
        [self.socket connectToHost:@"192.168.100.33" onPort:(UInt16)30000 error:&error];
    } @catch (NSException *exception) {
        NSLog(@"connect error : %@",error);
    }
    
}

- (void)reConnect{
    if(self.reConnectCount > maxReConnectCount){
        NSLog(@"重连次数过多，不在重连");
        return;
    }
    self.reConnectCount ++;
    self.isReConnect = YES;
    [self lineServerBtnClick];
    NSLog(@"重连次数 %ld",self.reConnectCount);
    
}
#pragma mark -- AsyncSocketDelegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    _isOnline = YES;
    self.isReConnect = NO;
    [sock readDataWithTimeout:-1 tag:0];
    self.reConnectCount = 0;
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFun) userInfo:nil repeats:YES];
     NSLog(@"%s",__func__);
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock{
     NSLog(@"%s",__func__);
    return  YES;
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSData *strData = [data subdataWithRange:NSMakeRange(0, data.length)];
    NSString *content = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];;
    if(content){
        self.textView.text = [NSString stringWithFormat:@"%@\n%@",content,self.textView.text];
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%s",__func__);
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    NSLog(@"%s",__func__);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

- (void)sendKeepAlive{
    NSLog(@"sendKeepAlive");
    if(self.socket.isConnected){
        
        NSMutableData *data = [NSMutableData dataWithCapacity:0];
        [self.socket writeData:data withTimeout:-1 tag:0];
    }else{
        [self reConnect];
    }
}

- (void)tapped:(id)sender{
    if(self.isOnline){
        NSString *toUserName = [self.toTextField.text copy];
        NSString *stringToSend = [self.textField.text copy];
        
        if(toUserName.length == 0 || stringToSend.length == 0){
            return;
        }
        
        JFPerson *toPerson = [[JFPerson alloc] init];
        toPerson.myName = toUserName;
        NSString *toUid = [NSString stringWithFormat:@"%ld", toPerson.userID];
        self.textField.text = @"";
        
        NSString *ip = [ViewController deviceIPAdress];
        int iID = NSSwapInt(10001);
        NSData *dataMsgId = [NSData dataWithBytes:&iID length:4];
        NSString *uid = [NSString stringWithFormat:@"%ld",self.person.userID];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:ip,@"IP", toUid,@"toUserID",toUserName,@"toUsername",uid,@"userID",self.person.myName,@"username",stringToSend,@"content", nil];
        
        NSString *jsonBody = [self json_jsonStringFromObject:dic];
        NSDictionary *dataDic = [NSDictionary dictionaryWithObjectsAndKeys:jsonBody,@"data", nil];
        jsonBody = [self json_jsonStringFromObject:dataDic];
        
        NSData *dataBody = [jsonBody dataUsingEncoding:NSUTF8StringEncoding];
        int lenBody =  NSSwapInt((unsigned int)[dataBody length]);
        NSData *dataLen = [NSData dataWithBytes:&lenBody length:4];
        NSMutableData *mData = [[NSMutableData alloc] init];
//        [mData appendData:dataMsgId];
//        [mData appendData:dataLen];
        [mData appendData:dataBody];
        [self.socket writeData:mData withTimeout:5 tag:0];
    }else{
        NSLog(@"暂未链接服务器");
    }
}

- (NSString *)json_jsonStringFromObject:(NSDictionary *)dic{
    if (!dic || [dic isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    NSData * data = [NSJSONSerialization dataWithJSONObject:dic options:kNilOptions error:nil];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

//必须在有网的情况下才能获取手机的IP地址

+ (NSString *)deviceIPAdress {
    
    NSString *address = @"an error occurred when obtaining ip address";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) { // 0 表示获取成功
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in  *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    NSLog(@"%@", address);
    return address;
}

@end
