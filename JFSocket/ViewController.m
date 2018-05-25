//
//  ViewController.m
//  JFSocket
//
//  Created by huangpengfei on 2018/5/25.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import "ViewController.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <arpa/inet.h>
@interface ViewController ()

@end

@implementation ViewController
{
    CFSocketRef _socket;
    BOOL _isOnline;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 50)];
    [btn setTitle:@"click me" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, nil, nil);
    if(_socket){
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_addr.s_addr = inet_addr("192.168.100.33");
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
    }
}

- (void)tapped:(id)sender{
    if(_isOnline){
        NSString *stringToSend = @"来自IOS客户端";
        const char * data = stringToSend.UTF8String;
        send(CFSocketGetNative(_socket), data, strlen(data) + 1, 1);
    }else{
        NSLog(@"暂未链接服务器");
    }
}
@end
