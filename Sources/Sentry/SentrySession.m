#import "SentrySession.h"
#import "NSDate+SentryExtras.h"
#import "SentryCurrentDate.h"
#import "SentryInstallation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SentrySession

@synthesize flagInit = _init;

/**
 * Default private constructor.
 */
- (instancetype)init
{
    if (self = [super init]) {
        _sessionId = [NSUUID UUID];
        _started = [SentryCurrentDate date];
        _status = kSentrySessionStatusOk;
        _sequence = 1;
        _errors = 0;
        _distinctId = [SentryInstallation id];
    }

    return self;
}

- (instancetype)initWithReleaseName:(NSString *)releaseName
{
    if (self = [self init]) {
        _init = @YES;
        _releaseName = releaseName;
    }
    return self;
}

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject
{
    // We use the default constructor here to set the non nullable values to a default values,
    // because this could cause crashes, for example, in serialize.
    // With this approach we avoid crashes and accept the tradeoff that some session data might not
    // be 100% accurate.
    if (self = [self init]) {
        NSUUID *sessionId = [[NSUUID UUID] initWithUUIDString:[jsonObject valueForKey:@"sid"]];
        if (nil != sessionId) {
            _sessionId = [[NSUUID UUID] initWithUUIDString:[jsonObject valueForKey:@"sid"]];
        }

        if ([[jsonObject valueForKey:@"started"] isKindOfClass:[NSString class]]) {
            _started = [NSDate sentry_fromIso8601String:[jsonObject valueForKey:@"started"]];
        }

        if ([[jsonObject valueForKey:@"status"] isKindOfClass:[NSString class]]) {
            NSString *status = [jsonObject valueForKey:@"status"];
            if ([@"ok" isEqualToString:status]) {
                _status = kSentrySessionStatusOk;
            } else if ([@"exited" isEqualToString:status]) {
                _status = kSentrySessionStatusExited;
            } else if ([@"crashed" isEqualToString:status]) {
                _status = kSentrySessionStatusCrashed;
            } else if ([@"abnormal" isEqualToString:status]) {
                _status = kSentrySessionStatusAbnormal;
            }
        }

        if (nil != [jsonObject valueForKey:@"seq"]) {
            _sequence = [[jsonObject valueForKey:@"seq"] unsignedIntegerValue];
        }

        if (nil != [jsonObject valueForKey:@"errors"]) {
            _errors = [[jsonObject valueForKey:@"errors"] unsignedIntegerValue];
        }

        if ([[jsonObject valueForKey:@"did"] isKindOfClass:[NSString class]]) {
            _distinctId = [jsonObject valueForKey:@"did"];
        }

        id init = [jsonObject valueForKey:@"init"];
        if (nil != init) {
            _init = init;
        }

        id attrs = [jsonObject valueForKey:@"attrs"];
        if (nil != attrs) {
            _releaseName = [attrs valueForKey:@"release"];
            _environment = [attrs valueForKey:@"environment"];
        }

        if ([[jsonObject valueForKey:@"timestamp"] isKindOfClass:[NSString class]]) {
            _timestamp = [NSDate sentry_fromIso8601String:[jsonObject valueForKey:@"timestamp"]];
        }

        NSNumber *duration = [jsonObject valueForKey:@"duration"];
        if (nil != duration) {
            _duration = duration;
        }
    }
    return self;
}

- (void)setFlagInit
{
    _init = @YES;
}

- (void)endSessionExitedWithTimestamp:(NSDate *)timestamp
{
    @synchronized(self) {
        [self changed];
        _status = kSentrySessionStatusExited;
        [self endSessionWithTimestamp:timestamp];
    }
}

- (void)endSessionCrashedWithTimestamp:(NSDate *)timestamp
{
    @synchronized(self) {
        [self changed];
        _status = kSentrySessionStatusCrashed;
        [self endSessionWithTimestamp:timestamp];
    }
}

- (void)endSessionAbnormalWithTimestamp:(NSDate *)timestamp
{
    @synchronized(self) {
        [self changed];
        _status = kSentrySessionStatusAbnormal;
        [self endSessionWithTimestamp:timestamp];
    }
}

- (void)endSessionWithTimestamp:(NSDate *)timestamp
{
    @synchronized(self) {
        _timestamp = timestamp;
        NSTimeInterval secondsBetween = [_timestamp timeIntervalSinceDate:_started];
        _duration = [NSNumber numberWithDouble:secondsBetween];
    }
}

- (void)changed
{
    _init = nil;
    _sequence++;
}

- (void)incrementErrors
{
    @synchronized(self) {
        [self changed];
        _errors++;
    }
}

- (NSDictionary<NSString *, id> *)serialize
{
    @synchronized(self) {
        NSMutableDictionary *serializedData = @{
            @"sid" : _sessionId.UUIDString,
            @"errors" : [NSNumber numberWithLong:_errors],
            @"started" : [_started sentry_toIso8601String],
        }
                                                  .mutableCopy;

        if (nil != _init) {
            [serializedData setValue:_init forKey:@"init"];
        }

        NSString *statusString = nil;
        switch (_status) {
        case kSentrySessionStatusOk:
            statusString = @"ok";
            break;
        case kSentrySessionStatusExited:
            statusString = @"exited";
            break;
        case kSentrySessionStatusCrashed:
            statusString = @"crashed";
            break;
        case kSentrySessionStatusAbnormal:
            statusString = @"abnormal";
            break;
        default:
            // TODO: Log warning
            break;
        }

        if (nil != statusString) {
            [serializedData setValue:statusString forKey:@"status"];
        }

        NSDate *timestamp = nil != _timestamp ? _timestamp : [SentryCurrentDate date];
        [serializedData setValue:[timestamp sentry_toIso8601String] forKey:@"timestamp"];

        if (nil != _duration) {
            [serializedData setValue:_duration forKey:@"duration"];
        } else if (nil == _init) {
            NSTimeInterval secondsBetween = [_timestamp timeIntervalSinceDate:_started];
            [serializedData setValue:[NSNumber numberWithDouble:secondsBetween] forKey:@"duration"];
        }

        // TODO: seq to be just unix time in mills?
        [serializedData setValue:[NSNumber numberWithLong:_sequence] forKey:@"seq"];

        if (nil != _releaseName || nil != _environment) {
            NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
            if (nil != _releaseName) {
                [attrs setValue:_releaseName forKey:@"release"];
            }

            if (nil != _environment) {
                [attrs setValue:_environment forKey:@"environment"];
            }
            [serializedData setValue:attrs forKey:@"attrs"];
        }

        [serializedData setValue:_distinctId forKey:@"did"];

        return serializedData;
    }
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    SentrySession *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy->_sessionId = _sessionId;
        copy->_started = _started;
        copy->_status = _status;
        copy->_errors = _errors;
        copy->_sequence = _sequence;
        copy->_distinctId = _distinctId;
        copy->_timestamp = _timestamp;
        copy->_duration = _duration;
        copy->_releaseName = _releaseName;
        copy.environment = self.environment;
        copy.user = self.user;
        copy->_init = _init;
    }

    return copy;
}

@end

NS_ASSUME_NONNULL_END
