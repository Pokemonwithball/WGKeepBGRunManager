//
//  WGProxy.m
//  WGKeepBGRunManager
//
//  Created by pokemon on 2021/4/2.
//

#import "WGProxy.h"

@implementation WGProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}


@end
