//
//  WGProxy.h
//  WGKeepBGRunManager
//
//  Created by pokemon on 2021/4/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGProxy : NSProxy

@property (weak, nonatomic) id target;


@end

NS_ASSUME_NONNULL_END
