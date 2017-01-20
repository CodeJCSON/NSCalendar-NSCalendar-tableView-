//
//  BoolValueSingleLeton.m
//  记录Demo
//
//  Created by user  on 2017/1/16.
//  Copyright © 2017年 Ligang. All rights reserved.
//

#import "BoolValueSingleLeton.h"

 static BoolValueSingleLeton *_instance = nil;
@implementation BoolValueSingleLeton

+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[BoolValueSingleLeton alloc] init];
    });
    return _instance;
}

-(void)setScrollDirection:(ScrollDirection )scrollDirection{
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
    }
}


@end
