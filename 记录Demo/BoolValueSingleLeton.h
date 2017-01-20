//
//  BoolValueSingleLeton.h
//  记录Demo
//
//  Created by user  on 2017/1/16.
//  Copyright © 2017年 Ligang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,ScrollDirection){//滑动方向
    ScrollDirectionNone = 0,
    ScrollDirectionUp = 1,
    ScrollDirectionDown = 2,
};

@interface BoolValueSingleLeton : NSObject

@property(nonatomic) ScrollDirection scrollDirection;//滑动方向

+(instancetype)sharedInstance;
@end
