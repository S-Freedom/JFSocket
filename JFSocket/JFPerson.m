//
//  JFPerson.m
//  JFSocket
//
//  Created by huangpengfei on 2018/5/28.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import "JFPerson.h"

@implementation JFPerson

- (instancetype)initName:(NSString *)name pwd:(NSString *)pwd{
    if(self = [super init]){
        self.myName = [name copy];
        self.pwd = [pwd copy];
    }
    return self;
}

- (void)setMyName:(NSString *)myName{
    _myName = myName;
    
    if([_myName.lowercaseString isEqualToString:@"jack"]){
        self.userID = 1001;
    }else  if([_myName.lowercaseString isEqualToString:@"tom"]){
        self.userID = 1002;
    } if([_myName.lowercaseString isEqualToString:@"jeff"]){
        self.userID = 1003;
    }
}

- (id)copyWithZone:(NSZone *)zone{
    
    JFPerson *person = [[[self class] allocWithZone:zone] init];
    person.myName = self.myName;
    person.pwd = self.pwd;
    person.userID = self.userID;
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    JFPerson *person = [[[self class] allocWithZone:zone] init];
    person.myName = self.myName;
    person.pwd = self.pwd;
    person.userID = self.userID;
    return  self;
}

#pragma mark NSCoding编码协议，一个对象实现了NSCoding协议方法，才能被转换成为二进制数据。
//编码方法，当对象被编码成二进制数据时调用。
-(void)encodeWithCoder:(NSCoder *)aCoder {
    //在编码方法中，需要对对象的每一个属性进行编码。
    [aCoder encodeObject:self.myName forKey:@"name"];
    [aCoder encodeObject:self.pwd forKey:@"pwd"];
    [aCoder encodeInteger:self.userID forKey:@"userID"];
}

//解码方法，当把二进制数据转成对象时调用。
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    //如果父类也遵守NSCoding协议，那么需要写self = [super initWithCoder]
    self = [super init];
    if (self) {
        [aDecoder encodeObject:self.myName forKey:@"name"];
        [aDecoder encodeObject:self.pwd forKey:@"pwd"];
        [aDecoder encodeInteger:self.userID forKey:@"userID"];
    }
    return self;
}

@end
