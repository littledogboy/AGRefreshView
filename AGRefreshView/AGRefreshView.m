//
//  AGRefreshView.m
//  AGRefreshView
//
//  Created by 吴书敏 on 16/6/2.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import "AGRefreshView.h"
#import "Masonry.h"
#import <objc/runtime.h>

@implementation AGRefreshView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame block:(void (^)())block scrollView:(UIScrollView *)scrollView
{
    self = [self initWithFrame:frame];
    if (self) {
        self.refreshBlock = block;
        self.scrollView = scrollView;
        self.isRefreshing = NO; // 默认也是no
        // refreshView 观察 scrollView 的偏移量
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:250/255.0 green:248/255.0 blue:251/255.0 alpha:1.0];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.image = [UIImage imageNamed:@"refresh01"];
        
        self.rotationView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
        self.rotationView.backgroundColor = [UIColor redColor];
        
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
        self.indicatorView.hidden = YES; // 初始状态下隐藏
        
        self.label = [[UILabel alloc] init];
        self.label.text = @"刷呀，刷呀，好累啊，喵^ω^";
        self.label.font = [UIFont systemFontOfSize:13];
        
        UIView *superView = self;
        
        [self addSubview:_imageView];
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(5));
            make.centerX.equalTo(superView);
            make.width.equalTo(@(195));
            make.height.equalTo(@(54));
        }];
        
        [self addSubview:_rotationView];
        [_rotationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_imageView.mas_bottom).offset(10);
            make.centerX.equalTo(_imageView.mas_left);
            make.width.equalTo(@(20));
            make.height.equalTo(_rotationView.mas_width);
        }];
        
        [self addSubview:_indicatorView];
        [_indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.and.right.equalTo(_rotationView);
        }];
        
        [self addSubview:_label];
        [_label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_rotationView.mas_right).offset(5);
            make.bottom.equalTo(_rotationView.mas_bottom);
            make.height.equalTo(_rotationView.mas_height);
        }];
        
    }
    return self;
}

#pragma mark-
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    NSValue *value = (NSValue *)[change objectForKey:@"new"];
    CGPoint offset = [value CGPointValue];
    
    // 核心： 进入每种状态的判断， 每个状态下的条件
    
    // 如果偏移量 > y,Noraml
    if (offset.y > self.frame.origin.y) {
        self.state = RefreshStateNormal;
        self.label.text = @"再拉, 再拉就刷给你看";
        self.isRefreshing = NO;
        [UIImageView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
            // 恢复到原来的状态
            self.rotationView.transform = CGAffineTransformMakeRotation(0);
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
    if (offset.y < self.frame.origin.y && self.isRefreshing == NO) {
        self.state = RefreshStatePulling;
        self.label.text = @"够了啦, 松开人家嘛";
        [UIImageView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
            self.rotationView.transform = CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            
        }];
    }
    
    // 如果拖拽结束,开始刷新,确保只进来一次 isRefreshing
    if (offset.y < self.frame.origin.y && self.scrollView.isDragging == NO && self.isRefreshing == NO) {
        self.indicatorView.hidden = NO; // 显示菊花
        [self.indicatorView startAnimating];
        self.rotationView.hidden = YES; // 隐藏箭头
        self.isRefreshing = YES; // 刷新状态
        self.state = RefreshStateRefreshing;
        self.label.text = @"刷呀，刷呀，好累啊，喵^ω^";
        [self.imageView addAnimationImagesWithFirstImageName:@"refresh01" type:nil duration:1.0 / 24.0 * 4.0];
        [self.imageView startAnimating];
        
        // 方式1
        [self.scrollView setContentOffset:CGPointMake(0, self.frame.origin.y) animated:YES];
        
        // 刷新持续时间：1. 固定时间 2. 网络请求时间 3. 如果网络不通常，固定时间返回
        self.refreshBlock();
    }
}

- (void)endRefresh
{
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    self.indicatorView.hidden = YES; // 隐藏菊花
    [self.indicatorView startAnimating];
    self.rotationView.hidden = NO; // 显示箭头
    self.isRefreshing = YES; // 非刷新状态
    [self.imageView stopAnimating];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // 添加约束
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(@(20));
        make.width.equalTo(@(195));
        make.height.equalTo(@(54));
    }];
}

@end

#pragma mark-
#pragma mark - scrollView 分类

@implementation UIScrollView (RefreshView)

@dynamic refreshView;

static void * MyRefreshViewKey = (void *)@"MyRefreshViewKey";

- (void)setRefreshView:(AGRefreshView *)refreshView
{
    objc_setAssociatedObject(self, MyRefreshViewKey, refreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AGRefreshView *)refreshView
{
    return objc_getAssociatedObject(self, MyRefreshViewKey);
}


- (void)addRefreshViewWithFrame:(CGRect)frame refreshingBlock:(void (^)())block;
{
    AGRefreshView *refreshView = [[AGRefreshView alloc] initWithFrame:frame block:block scrollView:self];
    self.refreshView = refreshView;
    [self addSubview:refreshView];
}

@end


#pragma mark-
#pragma mark - UIImageView 分类
@implementation UIImageView (addAnimationImages)

- (void)addAnimationImagesWithFirstImageName:(NSString *)firstImageName type:(NSString *)type duration:(CGFloat)duration
{
    int i = 0 ;
    NSString *filePath = firstImageName;
    NSString *blueFilePath = nil;
    
    if (type == nil) { // png
        blueFilePath = [filePath substringWithRange:NSMakeRange(0, filePath.length - 1)];
        i = [[firstImageName substringWithRange:NSMakeRange(firstImageName.length - 1, 1)] intValue];
    } else { // 非 png
        blueFilePath = [filePath substringWithRange:NSMakeRange(0, filePath.length - 1 - type.length)];
        i = [[firstImageName substringWithRange:NSMakeRange(firstImageName.length - 1 - type.length - 1, 1)] intValue];
    }
    
    NSMutableArray *mutableArray = [NSMutableArray array];
    UIImage *image = [UIImage imageNamed:filePath];
    
    while (image) {
        i++;
        [mutableArray addObject:image];
        if (type == nil) {
            filePath = [NSString stringWithFormat:@"%@%d", blueFilePath, i];
        } else {
            filePath = [NSString stringWithFormat:@"%@%d.%@", blueFilePath, i, type];
        }
        image = [UIImage imageNamed:filePath];
    }
    
    // 设置动画属性
    self.animationImages = mutableArray;
    self.animationDuration = duration;
}

@end



















