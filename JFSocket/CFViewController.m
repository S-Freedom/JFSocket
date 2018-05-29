//
//  ViewController.m
//  SocketDemo
//
//  Created by 黄鹏飞 on 2018/5/26.
//  Copyright © 2018年 HPF. All rights reserved.
//

#import "CFViewController.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <arpa/inet.h>

#define  ScreenW  [UIScreen mainScreen].bounds.size.width
#define  ScreenH  [UIScreen mainScreen].bounds.size.height

@interface CFViewController ()
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITextView *textView;
@end

@implementation CFViewController
{
    CFSocketRef _socket;
    BOOL _isOnline;
    NSString *_myName;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.textField resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _myName = @"IOS1";
    _dataArr = [NSMutableArray arrayWithCapacity:20];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 64, ScreenW - 20, 50)];
    textField.layer.borderColor = [UIColor blackColor].CGColor;
    textField.layer.borderWidth = 0.5f;
    textField.placeholder = @"input message to send";
    self.textField = textField;
    [self.view addSubview:textField];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 120, ScreenW - 20, ScreenH - 120 - 50 - 20)];
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont systemFontOfSize:14.0f];
    textView.layer.borderWidth = 0.5f;
    textView.layer.borderColor = [UIColor blackColor].CGColor;
    textView.userInteractionEnabled = NO;
    self.textView = textView;
    [self.view addSubview:textView];
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, ScreenH - 50, ScreenW, 50)];
    [btn setTitle:@"send" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, nil, nil);
    if(_socket){
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_addr.s_addr = inet_addr("192.168.1.101");
        addr4.sin_port = htons(30000);
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
        CFSocketError result = CFSocketConnectToAddress(_socket, address, 5);
        if(result == kCFSocketSuccess){
            _isOnline = YES;
            [NSThread detachNewThreadSelector:@selector(readStream) toTarget:self withObject:nil];
        }else{
            NSLog(@"result = %ld",(long)result);
        }
    }
    
}

- (void)readStream{
    char buffer[2048];
    NSInteger hasRead;
    while ((hasRead = recv(CFSocketGetNative(_socket), buffer, sizeof(buffer), 0))) {
        NSLog(@"%@", [[NSString alloc] initWithBytes:buffer length:hasRead encoding:NSUTF8StringEncoding]);
        NSString *str = [[NSString alloc] initWithBytes:buffer length:hasRead encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.text = [NSString stringWithFormat:@"%@\n%@",str, self.textView.text];
        });
        
    }
}

- (void)tapped:(id)sender{
    if(_isOnline){
        NSString *stringToSend = @"来自IOS客户端";
        NSString *text = [NSString stringWithFormat:@"%@说: %@",_myName,self.textField.text] ;
        if(text.length > 0){
            stringToSend = text;
        }
        self.textField.text = @"";
        const char * data = stringToSend.UTF8String;
        send(CFSocketGetNative(_socket), data, strlen(data) + 1, 1);
        
//        [self.dataArr addObject:stringToSend];
        
        
    }else{
        NSLog(@"暂未链接服务器");
    }
}
@end
