//
//  WGKeepBGRunManager.m
//  WGKeepBGRunManager
//
//  Created by pokemon on 2021/4/1.
//

#import "WGKeepBGRunManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "WGProxy.h"

///循环时间
static NSInteger _circulaDuration = 30; //ios13以后后台申请的时间最多为31秒
static WGKeepBGRunManager *_sharedManger;

@interface WGKeepBGRunManager ()
//UIBackgroundTaskIdentifier
@property (nonatomic,assign) UIBackgroundTaskIdentifier task;
///后台播放
@property (nonatomic,strong) AVAudioPlayer *playerBack;
@property (nonatomic, strong) NSTimer *timerAD;
///用来打印测试
@property (nonatomic, strong) NSTimer *timerLog;
@property (nonatomic,assign) NSInteger count;

@property (nonatomic, strong) WGProxy *wgProxy;

@end

@implementation WGKeepBGRunManager{
    CFRunLoopRef _runloopRef;
    dispatch_queue_t _queue;
}

+ (WGKeepBGRunManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedManger) {
            _sharedManger = [[WGKeepBGRunManager alloc] init];
        }
    });
    return _sharedManger;
}

-(WGProxy *)wgProxy{
    if (!_wgProxy) {
        _wgProxy = [WGProxy alloc];
        _wgProxy.target = self;
    }
    return _wgProxy;
}

//
- (instancetype)init {
    
    if (self = [super init]) {
        [self setupAudioSession];
        _queue = dispatch_queue_create("Mp3Play", NULL);
        //静音文件
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"mp3"];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        self.playerBack = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        [self.playerBack prepareToPlay];
        // 0.0~1.0,默认为1.0
        self.playerBack.volume = 0.01;
        // 循环播放
        self.playerBack.numberOfLoops = -1;
        
    }
    return self;
}


- (void)setupAudioSession {
    // 新建AudioSession会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 设置后台播放
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"Error setCategory AVAudioSession: %@", error);
    }
    NSLog(@"%d", audioSession.isOtherAudioPlaying);
    NSError *activeSetError = nil;
    // 启动AudioSession，如果一个前台app正在播放音频则可能会启动失败
    [audioSession setActive:YES error:&activeSetError];
    if (activeSetError) {
        NSLog(@"Error activating AVAudioSession: %@", activeSetError);
    }
}

/**
 启动后台运行
 */
- (void)startBGRun{
    [self.playerBack play];
    [self applyforBackgroundTask];
    dispatch_async(_queue, ^{
        //启动2个定时器 中间使用了一个第三方的类来控制，保证不会造成引用循环、后期再优化成gcd的定时器
        self.timerLog = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1 target:self.wgProxy selector:@selector(log) userInfo:nil repeats:YES];
        self.timerAD = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:_circulaDuration target:self.wgProxy selector:@selector(startAudioPlay) userInfo:nil repeats:YES];
        _runloopRef = CFRunLoopGetCurrent();
        [[NSRunLoop currentRunLoop] addTimer:self.timerAD forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:self.timerLog forMode:NSDefaultRunLoopMode];
        CFRunLoopRun();
    });
}

/**
 申请后台
 */
- (void)applyforBackgroundTask{
    self.task =[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.task];
            self.task = UIBackgroundTaskInvalid;
        });
    }];
}

/**
 打印
 */
- (void)log{
    _count = _count + 1;
    //直接使用角标来显示
    NSLog(@"我一直在打印%ld",_count);
    
}

/**
 检测后台运行时间
 */
- (void)startAudioPlay{
    _count = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([[UIApplication sharedApplication] backgroundTimeRemaining] < 30.0) {
            NSLog(@"后台快被杀死了");
            [self.playerBack play];
            [self applyforBackgroundTask];
        }
        else{
            NSLog(@"后台继续活跃呢");
        }///再次执行播放器停止，后台一直不会播放音乐文件
        [self.playerBack stop];
    });
}

/**
 停止后台运行
 */
- (void)stopBGRun{
    if (self.timerAD) {
        CFRunLoopStop(_runloopRef);
        // 关闭定时器即可
        [self.timerLog invalidate];
        self.timerLog = nil;
        [self.timerAD invalidate];
        self.timerAD = nil;
        [self.playerBack stop];
    }
    if (_task) {
        [[UIApplication sharedApplication] endBackgroundTask:_task];
        _task = UIBackgroundTaskInvalid;
    }
}


@end
