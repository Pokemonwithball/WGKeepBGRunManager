//
//  WGKeepBGRunManager.h
//  WGKeepBGRunManager
//
//  Created by pokemon on 2021/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGKeepBGRunManager : NSObject

+ (WGKeepBGRunManager *)shareManager;
/**
 开启后台运行
 */
- (void)startBGRun;

/**
 关闭后台运行
 */
- (void)stopBGRun;


@end

NS_ASSUME_NONNULL_END
