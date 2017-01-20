//
//  ViewController.m
//  记录Demo
//
//  Created by user  on 2017/1/9.
//  Copyright © 2017年 Ligang. All rights reserved.
//

#import "ViewController.h"
#import "CalendarCell.h"

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

#define LineColor ([UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0])

#define kItemSpace 2
#define kItemWidthHeight (kScreenWidth - 8 * kItemSpace)/7.0

typedef NS_ENUM(NSInteger,ScrollDirection){//滑动方向
    ScrollDirectionNone = 0,
    ScrollDirectionUp = 1,
    ScrollDirectionDown = 2,
};

@interface ViewController ()<UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>{
    NSMutableArray<UICollectionView *> *_collectionViewArray;
    NSMutableArray *_collectionViewHeightArr,*_dateArray;
    NSInteger _currentSelectedDay;
    ScrollDirection _endScrollDirection;//任意时刻的滑动方向；滑动结束时记录的滑动方向(不包含ScrollDirectionNone)
    float _maxYForBgView,_minYForBgView;
    float _maxYForScrollView,_minYForScrollView;
    float _offsetYOfScrollView,_offsetYOfBgView;
    NSArray *_cellTitleArray;
    
    BOOL _isScrolledToTop;//表格是否滑到顶部

}
@property (nonatomic , strong) NSDate *date;
@property (nonatomic , strong) NSDate *today;
@property (nonatomic , strong) NSDate *lastDate;
@property (nonatomic , strong) NSDate *nextDate;

@end

static NSString *collectionCellID = @"collectionCellID";
static NSString *tableViewCellID = @"tableViewCellID";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.today = [NSDate date];

    [self navigationBarConfiguration];

    [self onInitData];
    
}

#pragma mark - 导航栏设置
-(void)navigationBarConfiguration{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake((kScreenWidth-140)/2.0, 64-30-10, 140, 30)];
    textField.textColor = [UIColor blackColor];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.rightViewMode = UITextFieldViewModeAlways;
    textField.tag = 20;
    textField.delegate = self;
    textField.text = [NSString stringWithFormat:@"%lu年%lu月",[self yearInDate:self.today],[self monthInDate:self.today]];

    UIImage *leftImage = [UIImage imageNamed:@"left_img"];
    UIImageView *leftImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, leftImage.size.width, leftImage.size.height)];
    leftImgView.image = leftImage;
    leftImgView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *leftImgViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigaImgViewTouched:)];
    [leftImgView addGestureRecognizer:leftImgViewGesture];
    textField.leftView = leftImgView;
    
    UIImage *rightImage = [UIImage imageNamed:@"right_img"];
    UIImageView *rightImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, rightImage.size.width, rightImage.size.height)];
    rightImgView.image = rightImage;
    rightImgView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *rightImgViewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigaImgViewTouched:)];
    [rightImgView addGestureRecognizer:rightImgViewGesture];
    textField.rightView = rightImgView;

    [self.view addSubview:textField];
}

#pragma mark - 日期切换
-(void)navigaImgViewTouched:(UITapGestureRecognizer *)gesture{
    
    UITextField *textField = (UITextField *)[self.view viewWithTag:20];
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];

    if ([gesture.view isEqual:textField.leftView]) {//前面的月份
        //下面的方法不能用setContentOffset:方法替换，否则不会调用scrollViewDidEndScrollingAnimation方法；使用下面的方法时，不会调用scrollViewDidEndDecelerating方法，所以需要在scrollViewDidEndScrollingAnimation方法中调用scrollViewDidEndDecelerating方法，从而实现相关的逻辑
        [scrollView setContentOffset:CGPointMake(-kScreenWidth, 0) animated:YES];
    }else{//后面的月份
        [scrollView setContentOffset:CGPointMake(kScreenWidth*2, 0) animated:YES];
    }
}

-(void)onInitData{
    float kLabelWidth = kScreenWidth/7.0;
    NSArray *dayTitleArray = @[@"日",@"一",@"二",@"三",@"四",@"五",@"六"];
    for (int i = 0; i < 7; i ++) {
        UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(kLabelWidth*i, 64, kLabelWidth, 18)];
        dayLabel.text = dayTitleArray[i];
        dayLabel.tag = 20 + i;
        dayLabel.textColor = [UIColor lightGrayColor];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.font = [UIFont systemFontOfSize:14];
        if (i == 0 || i == dayTitleArray.count - 1) {
            dayLabel.textColor = [UIColor redColor];
        }
        [self.view addSubview:dayLabel];
    }
    
    _collectionViewHeightArr = [NSMutableArray array];
    [_collectionViewHeightArr addObject:@([self collectionViewHeightWithDate:[self lastMonthOfDate:self.today]])];
    [_collectionViewHeightArr addObject:@([self collectionViewHeightWithDate:self.today])];
    [_collectionViewHeightArr addObject:@([self collectionViewHeightWithDate:[self nextMonthOfDate:self.today]])];
 
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64+18, kScreenWidth, [_collectionViewHeightArr[1] floatValue])];
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.tag = 100;
    scrollView.contentSize = CGSizeMake(kScreenWidth*3, 0);
    scrollView.contentOffset = CGPointMake(kScreenWidth, 0);
    [self.view addSubview:scrollView];

    _collectionViewArray = [NSMutableArray array];
    for (int i = 0; i < 3; i ++) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(kItemWidthHeight, kItemWidthHeight);
        flowLayout.minimumLineSpacing = kItemSpace;
        flowLayout.minimumInteritemSpacing = kItemSpace;
        flowLayout.sectionInset = UIEdgeInsetsMake(kItemSpace, kItemSpace, kItemSpace, kItemSpace);
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(kScreenWidth * i, 0, kScreenWidth, [_collectionViewHeightArr[i] floatValue]) collectionViewLayout:flowLayout];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[CalendarCell class] forCellWithReuseIdentifier:collectionCellID];
        collectionView.tag = 200 + i;
        collectionView.backgroundColor = LineColor;
        [scrollView addSubview:collectionView];
        
        [_collectionViewArray addObject:collectionView];

    }
    
    _dateArray = [NSMutableArray array];
    self.date = self.today;
    self.lastDate = [self lastMonthOfDate:self.date];
    self.nextDate = [self nextMonthOfDate:self.date];
    
    [_dateArray addObjectsFromArray:@[self.lastDate,self.date,self.nextDate]];
    
    _currentSelectedDay = [self dayInDate:self.date];
    
    for (int i = 0; i < 3; i ++) {
        [self resetUIFrameWithIndex:i];
        UICollectionView *collectionView = [_collectionViewArray objectAtIndex:i];
        [collectionView reloadData];
    }

    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(scrollView.frame), kScreenWidth, 400)];
    bgView.tag = 300;
    bgView.backgroundColor = [UIColor redColor];
    [self.view addSubview:bgView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    [bgView addGestureRecognizer:panGesture];

    _cellTitleArray = @[@"来了",@"哈哈",@"心情",@"日记",@"体重",@"体温",@"不舒服",@"好习惯"];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 30+10, kScreenWidth, 352) style:UITableViewStyleGrouped];
    tableView.rowHeight = 44.0;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:tableViewCellID];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.scrollEnabled = NO;
    tableView.backgroundColor = [UIColor blueColor];
    tableView.tag = 400;
    [bgView addSubview:tableView];
    
    UIView *containView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 30)];
    containView.backgroundColor = [UIColor cyanColor];
    [bgView addSubview:containView];
    
    //总是在确定_currentSelectedDay后并且中间的collectionView刷新后就重置
    [self resetScrollViewMinYMaxY];
}

#pragma mark - 计算scrollView上下滑动的范围
-(void)resetScrollViewMinYMaxY{
    
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:self.date];
    //选中的cell的索引
    NSInteger selectedItem = firstWeekday+_currentSelectedDay-1;
    //选中的cell所在行
    NSInteger selectedRow = selectedItem/7;
    
    UICollectionView *collectionView = _collectionViewArray[1];
    NSInteger rowOfCollectionView = [collectionView numberOfItemsInSection:0]/7;
    
    _offsetYOfScrollView = selectedRow*(kItemSpace+kItemWidthHeight);
    
    _offsetYOfBgView = (rowOfCollectionView-1)*(kItemSpace+kItemWidthHeight);
    
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    _minYForScrollView = scrollView.center.y - _offsetYOfScrollView;
    _maxYForScrollView = scrollView.center.y;
    
    //红色视图
    UIView *bgView = (UIView *)[self.view viewWithTag:300];
    _minYForBgView = bgView.center.y-_offsetYOfBgView;
    _maxYForBgView = bgView.center.y;
 
}

#pragma mark - 手势事件处理
-(void)panGestureHandle:(UIPanGestureRecognizer *)panGesture{

    CGPoint translation = [panGesture translationInView:self.view];//手势拖动的距离(水平方向，竖直方向)
    //CGPoint velocity = [panGesture velocityInView:self.view];//手势拖动的速度(水平方向，竖直方向)
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        _endScrollDirection = ScrollDirectionNone;
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        [self changeScrollDirectionWithTranslation:translation];

        //限制上边视图(日历)的滑动范围
        UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
        CGPoint scrollViewCenter = CGPointMake(scrollView.center.x, scrollView.center.y+translation.y*_offsetYOfScrollView/_offsetYOfBgView);
        scrollViewCenter.y = MAX(_minYForScrollView, scrollViewCenter.y);
        scrollViewCenter.y = MIN(_maxYForScrollView, scrollViewCenter.y);
        scrollView.center = scrollViewCenter;
        
        //限制下边(红色)视图的滑动范围
        CGPoint newCenter = CGPointMake(panGesture.view.center.x, panGesture.view.center.y+translation.y);
        newCenter.y = MAX(_minYForBgView, newCenter.y);
        newCenter.y = MIN(_maxYForBgView, newCenter.y);
        panGesture.view.center = newCenter;
    }else if(panGesture.state == UIGestureRecognizerStateEnded){

        //向上滑
        if (_endScrollDirection == ScrollDirectionUp) {
            if (panGesture.view.center.y != _minYForBgView) {
                
                //panGesture.view的滑动距离小于1.2*(kItemSpace+kItemWidthHeight时回滚
                if (fabs(panGesture.view.center.y - _maxYForBgView) > 1.2*(kItemSpace+kItemWidthHeight)) {
                    [self viewsScrollUpWithPanGesture:panGesture];
                }else{
                    [self viewsScrollDownWithPanGesture:panGesture];
                }
            }
        }
        
        //向下滑
        if (_endScrollDirection == ScrollDirectionDown) {
            if (panGesture.view.center.y != _maxYForBgView) {
                [self viewsScrollDownWithPanGesture:panGesture];
            }
        }
    }
    
    //因为拖动起来一直是在递增，所以每次都要用setTranslation:方法将每次触摸都设置为0位置，这样才不至于不受控制般滑动视图
    [panGesture setTranslation:CGPointZero inView:self.view];

}

#pragma mark - 视图上滑
-(void)viewsScrollUpWithPanGesture:(UIPanGestureRecognizer *)panGesture{
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    CGPoint scrollViewCenter = scrollView.center;
    scrollViewCenter.y = _minYForScrollView;
    
    //红色视图
    CGPoint bgViewCenter = panGesture.view.center;
    bgViewCenter.y = _minYForBgView;
    
    //300为滑动速度，可以随意设置为合适的值
    NSTimeInterval interval = (panGesture.view.center.y-_minYForBgView)/300.0;
    
    [UIView animateWithDuration:interval animations:^{
        scrollView.center = scrollViewCenter;
        panGesture.view.center = bgViewCenter;
    } completion:^(BOOL finished) {
        _endScrollDirection = ScrollDirectionNone;
        _isScrolledToTop = YES;
    }];
}

#pragma mark - 视图下滑
-(void)viewsScrollDownWithPanGesture:(UIPanGestureRecognizer *)panGesture{
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    CGPoint scrollViewCenter = scrollView.center;
    scrollViewCenter.y = _maxYForScrollView;
    
    //红色视图
    CGPoint bgViewCenter = panGesture.view.center;
    bgViewCenter.y = _maxYForBgView;
    
    //300为滑动速度，可以随意设置为合适的值
    NSTimeInterval interval = (_maxYForBgView-panGesture.view.center.y)/300.0;
    
    [UIView animateWithDuration:interval animations:^{
        scrollView.center = scrollViewCenter;
        panGesture.view.center = bgViewCenter;
    } completion:^(BOOL finished) {
        _endScrollDirection = ScrollDirectionNone;
        _isScrolledToTop = NO;
    }];

}

//判断手势方向
-(void)changeScrollDirectionWithTranslation:(CGPoint )translation{
    if (translation.y > 0) {//向下滑
        _endScrollDirection = ScrollDirectionDown;
    }else if(translation.y < 0){//向上滑
        _endScrollDirection = ScrollDirectionUp;
    }
}

#pragma mark - 重置UIScrollView和CollectionView的frame
-(void)resetUIFrameWithIndex:(NSInteger )index{
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    CGRect scrollViewFrame = scrollView.frame;
    scrollViewFrame.origin.y = 64 + 18;
    scrollViewFrame.size.height = [_collectionViewHeightArr[index] floatValue];
    scrollView.frame = scrollViewFrame;
    
    UICollectionView *collectionView = _collectionViewArray[index];
    CGRect collectionViewFrame = collectionView.frame;
    collectionViewFrame.size.height = [_collectionViewHeightArr[index] floatValue];
    collectionView.frame = collectionViewFrame;
    [collectionView reloadData];
}

#pragma mark - 计算collectionView的高度
-(float)collectionViewHeightWithDate:(NSDate *)date{
    NSInteger daysInThisMonth = [self totaldaysInMonthOfDate:date];
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:date];
    
    if (daysInThisMonth == 28 && firstWeekday == 0) {
        return 4*kItemWidthHeight+5*kItemSpace;
    }
    
    if ((daysInThisMonth == 31 && firstWeekday >= 5) || (daysInThisMonth == 30 && firstWeekday == 6)) {
        return 6*kItemWidthHeight+7*kItemSpace;
    }
    
    return 5*kItemWidthHeight+6*kItemSpace;
}

#pragma mark - 日期setter
-(void)setDate:(NSDate *)date{
    _date = date;
}

-(void)setLastDate:(NSDate *)lastDate{
    _lastDate = lastDate;
}

-(void)setNextDate:(NSDate *)nextDate{
    _nextDate = nextDate;
}

-(void)setToday:(NSDate *)today{
    _today = today;
}

#pragma mark - date components
//日期的当天是几号
-(NSInteger )dayInDate:(NSDate *)date{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [components day];
}

//日期的月份
-(NSInteger )monthInDate:(NSDate *)date{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [components month];
}

//日期的年份
-(NSInteger )yearInDate:(NSDate *)date{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [components year];
}

//某个月的第一天是周几
-(NSInteger )firstWeekdayInThisMonth:(NSDate *)date{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    //设置每周的第一天的值 1对应周日（默认）
    [calendar setFirstWeekday:1];//Sun:1,Mon:2,Thes:3,Wed:4,Thur:5,Fri:6,Sat:7
    
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    [components setDay:1];
    
    NSDate *firstDayOfMonth = [calendar dateFromComponents:components];
    
    NSUInteger firstWeekday = [calendar ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:firstDayOfMonth];
    return firstWeekday - 1;//减1之前：1对应周日，2对应周一，...,7对应周六;减1后变为：0对应周日，1-6分别对应周一-周六
}

-(NSInteger )totaldaysInThisMonthOfDate:(NSDate *)date{
    NSRange totaldaysInMonth = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return totaldaysInMonth.length;
}

-(NSInteger )totaldaysInMonthOfDate:(NSDate *)date{
    NSRange totaldaysInMonth = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return totaldaysInMonth.length;
}

-(NSDate *)lastMonthOfDate:(NSDate *)date{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = -1;
    NSDate *newDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:date options:0];
    return newDate;
}

-(NSDate *)nextMonthOfDate:(NSDate *)date{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.month = 1;
    NSDate *newDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:date options:0];
    return newDate;
}

#pragma mark - UICollectionViewDelegate,UICollectionViewDataSource

-(NSInteger )collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{

    NSDate *_tempDate = self.date;
    if (collectionView.tag == 200) {
        _tempDate = self.lastDate;
    }
    
    if (collectionView.tag == 202) {
        _tempDate = self.nextDate;
    }

    NSInteger daysInThisMonth = [self totaldaysInMonthOfDate:_tempDate];
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:_tempDate];
    
    if (daysInThisMonth == 28 && firstWeekday == 0) {
        return 28;
    }
    
    if ((daysInThisMonth == 31 && firstWeekday >= 5) || (daysInThisMonth == 30 && firstWeekday == 6)) {
        return 42;
    }
    
    return 35;

}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CalendarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:collectionCellID forIndexPath:indexPath];
    
    NSDate *_tempDate = self.date;
    
    if (collectionView.tag == 200) {
        _tempDate = self.lastDate;
    }
    
    if (collectionView.tag == 202) {
        _tempDate = self.nextDate;
    }
    
    //某个月的天数
    NSInteger daysInThisMonth = [self totaldaysInMonthOfDate:_tempDate];
    
    //某个月的第一天是周几
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:_tempDate];
    
    //日期的那一天（几号）
    NSInteger day = 0;
    
    NSString *content = nil;
    UIColor *textColor = nil;
    if (indexPath.item < firstWeekday || indexPath.item > firstWeekday + daysInThisMonth -1 ) {
        content = @"";
    }else{
        day = indexPath.item - firstWeekday + 1;
        content = [NSString stringWithFormat:@"%lu",day];
        
        if ([_today isEqualToDate:_tempDate]) {
            if (day == [self dayInDate:_tempDate]) {//当前日期为今天
                textColor = [UIColor redColor];
            }else if (day > [self dayInDate:_tempDate]){
                textColor = [UIColor lightGrayColor];
            }
        }else if ([_today compare:_tempDate] == NSOrderedAscending){//_date为今天之后的日期
            textColor = [UIColor lightGrayColor];
        }
    }

    cell.dayLabel.textColor = textColor;
    cell.dayStr = content;
    cell.isSelected = NO;
    if (indexPath.row == firstWeekday + _currentSelectedDay -1) {
        cell.isSelected = YES;
    }
    return cell;
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger daysInThisMonth = [self totaldaysInMonthOfDate:_date];
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:_date];
    
   NSInteger day = indexPath.item - firstWeekday + 1;
    if (indexPath.row >= firstWeekday && indexPath.row <= firstWeekday + daysInThisMonth - 1) {
        if ([_today isEqualToDate:_date]) {
            if (day <= [self dayInDate:_date]) {
                return YES;
            }
        }else if ([_today compare:_date] == NSOrderedDescending){
            return YES;
        }
    }
    return NO;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:_date];
    
    NSInteger firstWeekday = [self firstWeekdayInThisMonth:_date];
    NSIndexPath *lastSelectedIndexPath = [NSIndexPath indexPathForRow:firstWeekday + _currentSelectedDay -1 inSection:0];
    _currentSelectedDay = indexPath.item - firstWeekday + 1;
    [collectionView reloadItemsAtIndexPaths:@[lastSelectedIndexPath,indexPath]];
    
    [self resetScrollViewMinYMaxY];

}

#pragma mark - UITableViewDelegate,UITableViewDataSource
-(NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 20;
}

-(CGFloat )tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(CGFloat )tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellID forIndexPath:indexPath];
    cell.textLabel.text = _cellTitleArray[indexPath.row];
    return cell;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    CGFloat offsetX = scrollView.contentOffset.x;
    
    NSInteger tempSelectedDay = _currentSelectedDay;
    _currentSelectedDay = 100;//该值与刷新collectionView时取消cell的选中状态有关，只要该值不在该collectionView的cell缩影范围内即可
    
    if (offsetX > kScreenWidth) {//向左滑 删除最左边的数据源（对应collectionView的高度，显示日期），并追加新的数据源
        self.date = _dateArray[2];
        self.lastDate = _dateArray[1];
        self.nextDate = [self nextMonthOfDate:self.date];
        [_dateArray removeObjectAtIndex:0];
        [_dateArray addObject:self.nextDate];
        
        [_collectionViewHeightArr removeObjectAtIndex:0];
        [_collectionViewHeightArr addObject:@([self collectionViewHeightWithDate:self.nextDate])];
        [self resetUIFrameWithIndex:2];
        
        NSInteger firstWeekday = [self firstWeekdayInThisMonth:self.lastDate];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:firstWeekday+tempSelectedDay-1 inSection:0];
        UICollectionView *collectionView = _collectionViewArray[2];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
    }else if (offsetX < kScreenWidth){//向右滑 删除最右边的数据源（对应collectionView的高度，显示日期），并插入新的数据源
        self.date = _dateArray[0];
        self.nextDate = _dateArray[1];
        self.lastDate = [self lastMonthOfDate:self.date];
        [_dateArray removeObjectAtIndex:2];
        [_dateArray insertObject:self.lastDate atIndex:0];

        [_collectionViewHeightArr removeObjectAtIndex:2];
        [_collectionViewHeightArr insertObject:@([self collectionViewHeightWithDate:self.lastDate]) atIndex:0];
        [self resetUIFrameWithIndex:0];
        
        //取消对原来显示的cell的选中
        NSInteger firstWeekday = [self firstWeekdayInThisMonth:self.lastDate];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:firstWeekday+tempSelectedDay-1 inSection:0];
        UICollectionView *collectionView = _collectionViewArray[0];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];

    }
    
    _currentSelectedDay = tempSelectedDay;
    
    [self resetScrollViewMinYMaxY];

    [self resetUIFrameWithIndex:1];

    UIView *bgView = (UIView *)[self.view viewWithTag:300];

    float minusY = CGRectGetMinY(bgView.frame) - CGRectGetMaxY(scrollView.frame);
    [UIView animateWithDuration:0.2 animations:^{
        bgView.transform = CGAffineTransformTranslate(bgView.transform, 0, -minusY);
    }];

    UITextField *textField = (UITextField *)[self.view viewWithTag:20];
    textField.text = [NSString stringWithFormat:@"%lu年%lu月",[self yearInDate:self.date],[self monthInDate:self.date]];
    
    //下面的方法不能用setContentOffset:animated:方法，否则会调用scrollViewDidEndScrollingAnimation方法而导致死循环
    scrollView.contentOffset = CGPointMake(kScreenWidth, 0);
}

//调用setContentOffset:animated:方法来滚动视图时会调用下面的方法，调用没动画的方法setContentOffset:时不会调用下面的方法
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self scrollViewDidEndDecelerating:scrollView];
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
