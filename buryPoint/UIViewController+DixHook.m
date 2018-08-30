
//
//  UIViewController+DixHook.m
//  buryPoint
//
//  Created by Shannon MYang on 2018/8/28.
//  Copyright © 2018年 Shannon MYang. All rights reserved.
//

#import "UIViewController+DixHook.h"
#import <objc/runtime.h>

@implementation UIViewController (DixHook)

//swizzling 应该只在 +load 中完成。
+ (void)load {
    //swizzling 应该只在 dispatch_once 中完成。
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(dix_viewDidAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // 当交换方法是类方法的时候，用以下的内容
        // Class class = object_getClass((id)self);
        //
        // SEL originalSelector = @selector(xxxxxxx);
        // SEL swizzledSelector = @selector(dix_xxxxxxx);
        //
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        /*
         * class_addMethod方法会给这个类添加一个方法
         * 如果这个类（本身，不包括父类）已经有了originalSelector，则无法添加成功，同时返回NO
         * 所以这里的意义是：如果这个类（自身，不包括父类）没有originSelector，则给它添加一个方法，而方法实现对应于swizzledMethod
         */
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        /*
         * 如果给这个类添加originSelector成功，则让这个类的swizzledSelector的实现变成originalMethod
         */
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        }
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method swizzling
- (void)dix_viewDidAppear:(BOOL)animated
{
    NSString *appearDetailInfo = [NSString stringWithFormat:@" %@ - %@", NSStringFromClass([self class]), @"didAppear"];
    NSLog(@"UIViewController swizzling --> %@", appearDetailInfo);
    [self dix_viewDidAppear:animated];
}

@end
