#import "AppDelegate.h"
@import Sentry;

@interface
AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
        options.dsn = @"https://8ee5199a90354faf995292b15c196d48@o19635.ingest.sentry.io/4394";
        options.debug = @YES;
        options.logLevel = kSentryLogLevelVerbose;
        options.enableAutoSessionTracking = @YES;
        options.attachStacktrace = @YES;
        options.sessionTrackingIntervalMillis =
            [@5000 unsignedIntegerValue]; // 5 seconds session timeout for testing
    }];

    return YES;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options
{
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                          sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application
    didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions
{
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running,
    // this will be called shortly after
    // application:didFinishLaunchingWithOptions. Use this method to release any
    // resources that were specific to the discarded scenes, as they will not
    // return.
}

@end
