#import "SentryAppStartTrackingIntegration.h"
#import "SentryAppStartTracker.h"
#import "SentryDefaultCurrentDateProvider.h"
#import <Foundation/Foundation.h>
#import <SentryAppStateManager.h>
#import <SentryClient+Private.h>
#import <SentryCrashAdapter.h>
#import <SentryDispatchQueueWrapper.h>
#import <SentryHub.h>
#import <SentrySDK+Private.h>
#import <SentrySystemInfo.h>

@interface
SentryAppStartTrackingIntegration ()

@property (nonatomic, strong) SentryAppStartTracker *tracker;

@end

@implementation SentryAppStartTrackingIntegration

- (void)installWithOptions:(SentryOptions *)options
{
    SentryDefaultCurrentDateProvider *currentDateProvider =
        [[SentryDefaultCurrentDateProvider alloc] init];
    SentryCrashAdapter *crashAdapter = [[SentryCrashAdapter alloc] init];
    SentrySystemInfo *systemInfo = [[SentrySystemInfo alloc] init];

    SentryAppStateManager *appStateManager = [[SentryAppStateManager alloc]
            initWithOptions:options
               crashAdapter:crashAdapter
                fileManager:[[[SentrySDK currentHub] getClient] fileManager]
        currentDateProvider:currentDateProvider
                 systemInfo:systemInfo];

    self.tracker =
        [[SentryAppStartTracker alloc] initWithOptions:options
                                   currentDateProvider:currentDateProvider
                                  dispatchQueueWrapper:[[SentryDispatchQueueWrapper alloc] init]
                                       appStateManager:appStateManager
                                           processInfo:systemInfo];
    [self.tracker start];
}

- (void)uninstall
{
    [self stop];
}

- (void)stop
{
    if (nil != self.tracker) {
        [self.tracker stop];
    }
}

@end