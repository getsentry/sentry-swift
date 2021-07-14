#import <Foundation/Foundation.h>
#import <NSData+Sentry.h>
#import <SentryBreadcrumb.h>
#import <SentryCrashJSONCodec.h>
#import <SentryCrashJSONCodecObjC.h>
#import <SentryCrashScopeObserver.h>
#import <SentryLog.h>
#import <SentryScopeSyncC.h>
#import <SentryUser.h>

@interface
SentryCrashScopeObserver ()
@property (nonatomic, assign) NSInteger maxBreadcrumbs;

@end

@implementation SentryCrashScopeObserver

- (instancetype)initWithMaxBreadcrumbs:(NSInteger)maxBreadcrumbs
{
    if (self = [super init]) {
        self.maxBreadcrumbs = maxBreadcrumbs;
        sentryscopesync_configureBreadcrumbs(maxBreadcrumbs);
    }

    return self;
}

- (void)setUser:(nullable SentryUser *)user
{
    [self syncScope:user
        serialize:^{ return @ { @"user" : [user serialize] }; }
        scopeSync:^(const void *bytes) { sentryscopesync_setUser(bytes); }];
}

- (void)setDist:(nullable NSString *)dist
{
    [self syncScope:dist
        serialize:^{ return @ { @"dist" : dist }; }
        scopeSync:^(const void *bytes) { sentryscopesync_setDist(bytes); }];
}

- (void)setEnvironment:(nullable NSString *)environment
{
    [self syncScope:environment
        serialize:^{ return @ { @"environment" : environment }; }
        scopeSync:^(const void *bytes) { sentryscopesync_setEnvironment(bytes); }];
}

- (void)setContext:(nullable NSDictionary<NSString *, id> *)context
{
    [self syncScope:context
              field:@"context"
          scopeSync:^(const void *bytes) { sentryscopesync_setContext(bytes); }];
}

- (void)setExtras:(nullable NSDictionary<NSString *, id> *)extras
{
    [self syncScope:extras
              field:@"extra"
          scopeSync:^(const void *bytes) { sentryscopesync_setExtras(bytes); }];
}

- (void)setTags:(nullable NSDictionary<NSString *, NSString *> *)tags
{
    [self syncScope:tags
              field:@"tags"
          scopeSync:^(const void *bytes) { sentryscopesync_setTags(bytes); }];
}

- (void)setFingerprint:(nullable NSArray<NSString *> *)fingerprint
{
    [self syncScope:fingerprint
        serialize:^{
            NSDictionary *result = nil;
            if (fingerprint.count > 0) {
                result = @ { @"fingerprint" : fingerprint };
            }
            return result;
        }
        scopeSync:^(const void *bytes) { sentryscopesync_setFingerprint(bytes); }];
}

- (void)setLevel:(enum SentryLevel)level
{
    if (level == kSentryLevelNone) {
        sentryscopesync_setLevel(NULL);
        return;
    }

    NSDictionary *serialized = @{ @"level" : SentryLevelNames[level] };
    NSData *json = [self toJSONAsCString:serialized];
    if (json == nil) {
        return;
    }

    sentryscopesync_setLevel([json bytes]);
}

- (void)addBreadcrumb:(SentryBreadcrumb *)crumb
{
    NSDictionary *serialized = [crumb serialize];
    NSData *json = [self toJSONAsCString:serialized];
    if (json == nil) {
        return;
    }

    sentryscopesync_addBreadcrumb([json bytes]);
}

- (void)clearBreadcrumbs
{
    sentryscopesync_clearBreadcrumbs();
}

- (void)clear
{
    sentryscopesync_clear();
}

- (void)syncScope:(nullable NSDictionary *)dict
            field:(NSString *)field
        scopeSync:(void (^)(const void *))scopeSync
{
    [self syncScope:dict
          serialize:^{
              NSDictionary *result = nil;
              if (dict.count > 0) {
                  result = @ { field : dict };
              }
              return result;
          }
          scopeSync:scopeSync];
}

- (void)syncScope:(nullable id)object
        serialize:(nullable NSDictionary * (^)(void))serialize
        scopeSync:(void (^)(const void *))scopeSync
{
    if (object == nil) {
        scopeSync(NULL);
        return;
    }

    NSDictionary *serialized = serialize();
    if (serialized == nil) {
        scopeSync(NULL);
        return;
    }

    NSData *jsonCString = [self toJSONAsCString:serialized];
    if (jsonCString == nil) {
        return;
    }

    scopeSync([jsonCString bytes]);
}

- (nullable NSData *)toJSONAsCString:(NSDictionary *)serialized
{
    NSError *error = nil;
    NSData *json = nil;
    if (serialized != nil) {
        json = [SentryCrashJSONCodec encode:serialized
                                    options:SentryCrashJSONEncodeOptionSorted
                                      error:&error];
        if (error != nil) {
            NSString *message = [NSString stringWithFormat:@"Could not serialize %@", error];
            [SentryLog logWithMessage:message andLevel:kSentryLevelError];
            return nil;
        }
    }

    // Remove first { and last }
    NSRange range = NSMakeRange(1, [json length] - 2);
    json = [json subdataWithRange:range];
    // C strings need to be null terminated
    return [json nullTerminated];
}

@end
