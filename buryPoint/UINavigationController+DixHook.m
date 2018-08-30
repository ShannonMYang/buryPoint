//
//  UINavigationController+DixHook.m
//  buryPoint
//
//  Created by Shannon MYang on 2018/8/28.
//  Copyright © 2018年 Shannon MYang. All rights reserved.
//

#import "UINavigationController+DixHook.h"
#import <objc/runtime.h>

@implementation UINavigationController (DixHook)

//swizzling 应该只在 +load 中完成。
+ (void)load {
    //swizzling 应该只在 dispatch_once 中完成。
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        //Push
        SEL originalPushSelector = @selector(pushViewController:animated:);
        SEL swizzledPushSelector = @selector(dix_pushViewController:animated:);
        
        Method originalPushMethod = class_getInstanceMethod(class, originalPushSelector);
        Method swizzledPushMethod = class_getInstanceMethod(class, swizzledPushSelector);
        
        BOOL didAddPushMethod = class_addMethod(class, originalPushSelector, method_getImplementation(swizzledPushMethod), method_getTypeEncoding(swizzledPushMethod));
        
        if (didAddPushMethod) {
            class_replaceMethod(class, swizzledPushSelector, method_getImplementation(originalPushMethod), method_getTypeEncoding(originalPushMethod));
        }
        else {
            method_exchangeImplementations(originalPushMethod, swizzledPushMethod);
        }
        //Pop
        SEL originalPopSelector = @selector(popViewControllerAnimated:);
        SEL swizzledPopSelector = @selector(dix_popViewControllerAnimated:);
        
        Method originalPopMethod = class_getInstanceMethod(class, originalPopSelector);
        Method swizzledPopMethod = class_getInstanceMethod(class, swizzledPopSelector);
        
        BOOL didAddPopMethod = class_addMethod(class, originalPopSelector, method_getImplementation(swizzledPopMethod), method_getTypeEncoding(swizzledPushMethod));
        
        if (didAddPopMethod) {
            class_replaceMethod(class, swizzledPopSelector, method_getImplementation(originalPopMethod), method_getTypeEncoding(originalPopMethod));
        }
        else {
            method_exchangeImplementations(originalPopMethod, swizzledPopMethod);
        }
    });
}

- (void)dix_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSString *popDetailInfo = [NSString stringWithFormat: @"%@ - %@ - %@", NSStringFromClass([self class]), @"push", NSStringFromClass([viewController class])];
    NSLog(@"UINavigationController swizzling --> %@", popDetailInfo);
    [self dix_pushViewController:viewController animated:animated];
}

- (void)dix_popViewControllerAnimated:(BOOL)animated
{
    NSString *popDetailInfo = [NSString stringWithFormat:@"%@ - %@", NSStringFromClass([self class]), @"pop"];
    NSLog(@"UINavigationController swizzling --> %@", popDetailInfo);
    [self dix_popViewControllerAnimated:animated];
}

@end
