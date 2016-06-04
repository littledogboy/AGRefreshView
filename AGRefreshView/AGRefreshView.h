//
//  AGRefreshView.h
//  AGRefreshView
//
//  Created by 吴书敏 on 16/6/2.
//  Copyright © 2016年 littledogboy. All rights reserved.
//

#import <UIKit/UIKit.h>

// 下拉过程
typedef NS_ENUM(NSUInteger, RefreshState)
{
    RefreshStateNormal,
    RefreshStatePulling,
    RefreshStateRefreshing,
    RefreshStateDone
};

@interface AGRefreshView : UIView

// 内部控件
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *rotationView;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

// 父视图
@property (nonatomic, strong) UIScrollView *scrollView;

// 刷新时进行的网络回调
@property (nonatomic, copy) void (^refreshBlock)();

// 是否在刷新
@property (nonatomic, assign) BOOL isRefreshing;

// 视图状态
@property (nonatomic, assign) RefreshState state;

// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame block:(void (^)())block scrollView:(UIScrollView *)scrollView;

// 结束刷新
- (void)endRefresh;

@end


#pragma mark- UIScrollView 分类

@interface UIScrollView (RefreshView)

// 添加属性
@property (nonatomic, strong) AGRefreshView *refreshView;

// 添加下拉刷新视图，以及 刷新时的block
- (void)addRefreshViewWithFrame:(CGRect)frame refreshingBlock:(void (^)())block;

@end

#pragma mark- UIImageView 分类
@interface UIImageView (addAnimationImages)

- (void)addAnimationImagesWithFirstImageName:(NSString *)firstImageName type:(NSString *)type duration:(CGFloat)duration;

@end










