//
//  CalendarCell.m
//  记录Demo
//
//  Created by user  on 2017/1/9.
//  Copyright © 2017年 Ligang. All rights reserved.
//

#import "CalendarCell.h"

@interface CalendarCell ()

@end
@implementation CalendarCell
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self onInitData];
    }
    return self;
}

-(void)onInitData{
    self.backgroundColor = [UIColor whiteColor];
    
    self.layer.cornerRadius = 2.0;
    self.layer.masksToBounds = YES;
    
    _dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 4, 20, 20)];
    _dayLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:_dayLabel];
}

-(void)setDayStr:(NSString *)dayStr{
    if (_dayStr != dayStr) {
        _dayStr = dayStr;
    }
    _dayLabel.text = _dayStr;
}

-(void)setIsSelected:(BOOL)isSelected{
    if (_isSelected != isSelected) {
        _isSelected = isSelected;
    }
    
    if (_isSelected) {
        self.layer.borderColor = [UIColor redColor].CGColor;
        self.layer.borderWidth = 1.0;
    }else{
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 0.0;
    }
}
@end
