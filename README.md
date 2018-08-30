## buryPoint

> ##### 一个简单的埋点小demo，用来显示每个页面出现的次数、按钮的点击、视图的跳转，此处做简单的打印处理。

---

> #### `场景一`：
> ##### 假设我们想要在一款 iOS App 中 `追踪每一个视图控制器被用户呈现了几次`： 
> `方案`1️⃣ `--->` 可以通过在每个视图控制器的 viewDidAppear: 方法中添加追踪代码来实现，但这样会大量重复的样板代码。
> `方案`2️⃣ `--->` 继承是另一种可行的方式，但是这要求所有被继承的视图控制器如 UIViewController, UITableViewController, UINavigationController 都在 viewDidAppear：实现追踪代码，这同样会造成很多重复代码。 
> `方案`3️⃣ `--->` 幸运的是，这里有另外一种可行的方式：从 category 实现 method swizzling 。

##### 实现方式如下：
```objective-c
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
```

---

> #### `场景二`：
> ##### 假设我们想要在一款iOS App中，记录用户的进行了什么样的操作，比如：点击了哪个按钮
> `方案`： 使用 `runtime` 中的方法 `hook 下sendAction:to:forEvent:` 便可以知道用户进行了什么样的交互操作。
> 这个方法对 `UIControl` 及 `继承于 UIControl` 而实现的`子类对象`是有效的，比如 `UIButton、UISlider、UIDatePicker、UISegmentControl` 等。


##### 实现方式如下：
```objective-c
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
```

---

> #### `场景三`：
> ##### 假设我们想要在一款iOS App中，记录用户是从哪个页面跳转到哪个页面？当前停留在是哪个界面？
> iOS 中页面切换有两种方式：UIViewController 中的 `presentViewController:animated:` 和 `dismissViewController:completion:` ；UINavigationController 中的 `pushViewController:animated:` 和 `popViewControllerAnimated:` 。
> 但是，对于 UIViewController 来说，我们不对这两个方法 hook，因为页面跳来跳去，记录下来的各种数据会很多很乱，不利于后续查看。
> `方案`： hook 下 `ViewDidAppear:` 这个方法知道哪个页面显示了就足够了，而所有显示的页面按时间顺序连成序列，便是用户操作后应用中的页面跳转的轨迹。

##### 实现方式：
```objective-c
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
```