//
//  Created by ktiays on 2025/3/1.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import <string>

#import "GTFHook.h"

@implementation NSObject (GTFHook)

- (void)gtf_addInstanceMethod:(SEL)selector withBlock:(void (^)(id))block {
    IMP imp = imp_implementationWithBlock(^(id object, SEL selector) {
        block(object);
    });
    class_addMethod(self.class, selector, imp, "v@:");
}

- (void)gtf_addInstanceMethod:(SEL)selector withCGRectArgBlock:(void (^)(id, CGRect))block {
    IMP imp = imp_implementationWithBlock(^(id object, CGRect arg) {
        block(object, arg);
    });
    std::string type = std::string("v@:") + @encode(CGRect);
    class_addMethod(self.class, selector, imp, type.c_str());
}

- (void)gtf_addInstanceMethod:(SEL)selector withBlockReturnsBoolean:(BOOL (^)(id))block {
    IMP imp = imp_implementationWithBlock(^(id object) {
        return block(object);
    });
    class_addMethod(self.class, selector, imp, "c@:");
}

- (void)gtf_addInstanceMethod:(SEL)selector withBlockReturnsCGFloat:(CGFloat (^)(id))block {
    IMP imp = imp_implementationWithBlock(^(id object) {
        return block(object);
    });
    class_addMethod(self.class, selector, imp, "f@:");
}

- (void)gtf_invokeSuperForSelector:(SEL)selector {
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    ((void (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superStruct, selector);
}

- (void)gtf_invokeSuperForSelector:(SEL)selector withRect:(CGRect)rect {
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    ((void (*)(struct objc_super *, SEL, CGRect)) objc_msgSendSuper)(&superStruct, selector, rect);
}

- (BOOL)gtf_invokeSuperForSelectorReturnsBoolean:(SEL)selector {
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    return ((BOOL (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superStruct, selector);
}

- (CGFloat)gtf_invokeSuperForSelectorReturnsCGFloat:(SEL)selector {
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    return ((CGFloat (*)(struct objc_super *, SEL)) objc_msgSendSuper)(&superStruct, selector);
}

- (BOOL)gtf_invokeSuperForSelector:(SEL)selector withBooleanArgReturnsBoolean:(BOOL)arg {
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    return ((BOOL (*)(struct objc_super *, SEL, BOOL)) objc_msgSendSuper)(&superStruct, selector, arg);
}

- (id)gtf_getObjectIvar:(NSString *)ivarName {
    Ivar ivar = class_getInstanceVariable(self.class, ivarName.UTF8String);
    return object_getIvar(self, ivar);
}

- (IMP)gtf_getImplementationForSelector:(SEL)selector {
    Method method = class_getInstanceMethod(self.class, selector);
    return method_getImplementation(method);
}

@end
