//
//  Created by ktiays on 2025/3/1.
//  Copyright (c) 2025 ktiays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (GTFHook)

- (void)gtf_addInstanceMethod:(SEL)selector withBlock:(void (^)(NSObject *))block;
- (void)gtf_addInstanceMethod:(SEL)selector withCGRectArgBlock:(void (^)(NSObject *, CGRect))block;
- (void)gtf_addInstanceMethod:(SEL)selector withBlockReturnsCGFloat:(CGFloat (^)(NSObject *))block;
- (void)gtf_addInstanceMethod:(SEL)selector withBlockReturnsBoolean:(BOOL (^)(NSObject *))block;

- (void)gtf_invokeSuperForSelector:(SEL)selector;
- (BOOL)gtf_invokeSuperForSelectorReturnsBoolean:(SEL)selector;
- (CGFloat)gtf_invokeSuperForSelectorReturnsCGFloat:(SEL)selector;
- (void)gtf_invokeSuperForSelector:(SEL)selector withRect:(CGRect)rect;
- (BOOL)gtf_invokeSuperForSelector:(SEL)selector withBooleanArgReturnsBoolean:(BOOL)arg;

- (id)gtf_getObjectIvar:(NSString *)ivarName;

- (IMP)gtf_getImplementationForSelector:(SEL)selector;

@end
