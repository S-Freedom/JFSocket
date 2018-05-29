//
//  JFPerson.h
//  JFSocket
//
//  Created by huangpengfei on 2018/5/28.
//  Copyright © 2018年 huangpengfei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JFPerson : NSObject<NSCopying,NSMutableCopying,NSCoding>
@property(nonatomic, copy) NSString *myName;
@property(nonatomic, copy) NSString *pwd;
@property(nonatomic, assign) long userID;

- (instancetype)initName:(NSString *)name pwd:(NSString *)pwd;

@end
