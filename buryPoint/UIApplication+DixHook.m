//
//  UIApplication+DixHook.m
//  buryPoint
//
//  Created by Shannon MYang on 2018/8/28.
//  Copyright © 2018年 Shannon MYang. All rights reserved.
//

#import "UIApplication+DixHook.h"
#import <objc/runtime.h>

@implementation UIApplication (DixHook)

//swizzling 应该只在 +load 中完成。
+ (void)load {
    //swizzling 应该只在 dispatch_once 中完成。
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(sendAction:to:from:forEvent:);
        SEL swizzledSelector = @selector(dix_sendAction:to:from:forEvent:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            //NSLog(@"--------------------------");
        }
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
            //NSLog(@"++++++++++++++++++++++++++");
        }
        //NSLog(@"%d", didAddMethod);
    });
}


- (BOOL)dix_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent *)event;
{
    NSString *actionDetailInfo = [NSString stringWithFormat:@" %@ - %@ - %@", NSStringFromClass([target class]), NSStringFromClass([sender class]), NSStringFromSelector(action)];
    NSLog(@"UIApplication swizzling --> %@", actionDetailInfo);
    return [self dix_sendAction:action to:target from:sender forEvent:event];
}

@end
