#import "SentryTransactionContext.h"

@implementation SentryTransactionContext

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [self init]) {
        _name = [NSString stringWithString:name];
        self.parentSampled = false;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(SentrySpanId *)parentSpanId
            andParentSampled:(BOOL)parentSampled
{
    if ([super initWithTraceId:traceId spanId:spanId parentId:parentSpanId sampled:false]) {
        _name = [NSString stringWithString:name];
        self.parentSampled = parentSampled;
    }
    return self;
}

@end
