//
//  CalendarCell.h
//  记录Demo
//
//  Created by user  on 2017/1/9.
//  Copyright © 2017年 Ligang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalendarCell : UICollectionViewCell
@property(nonatomic,copy) NSString *dayStr;
@property(nonatomic,strong) UILabel *dayLabel;
@property(nonatomic) BOOL isSelected;
@end
