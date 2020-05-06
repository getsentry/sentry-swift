#import <Foundation/Foundation.h>
#import "SentryRateLimitParser.h"
#import "SentryCurrentDate.h"
#import "SentryRateLimitCategoryMapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface SentryRateLimitParser ()

@end

@implementation SentryRateLimitParser

- (NSDictionary<NSNumber *, NSDate *> *)parse:(NSString *)header {
    
    NSMutableDictionary<NSNumber *, NSDate *> *rateLimits = [[NSMutableDictionary alloc] init];
    
    if ([header length] == 0)  {
        return rateLimits;
    }
    
    // The header might contain whitespaces and they must be ignored.
    NSString *headerNoWhitespaces = [self removeAllWhitespaces:header];
    
    NSArray<NSString *> *quotaLimits = [headerNoWhitespaces componentsSeparatedByString:@","];
    
    // Each quotaLimit exists of retryAfter:categories:scope. The scope is ignored here
    // as it can be ignored by SDKs.
    for (NSString* quota in quotaLimits) {
        NSArray<NSString *> *parameters = [quota componentsSeparatedByString:@":"];
        
        NSNumber *retryAfterInSeconds = [self getRetryAfterInSeconds:parameters[0]];
        if (nil == retryAfterInSeconds || [retryAfterInSeconds intValue] <= 0) {
            continue;
        }
        
        // The categories are a semicolon separated list. If this parameter is empty it stands
        // for all categories. componentsSeparatedByString returns one category even if this
        // parameter is empty.
        NSArray<NSString *> *categories =  [parameters[1] componentsSeparatedByString:@";"];
        for (NSString *categoryAsString in categories) {
            SentryRateLimitCategory category = [self mapStringToCategory:categoryAsString];
            rateLimits[[NSNumber numberWithInt:category]] = [SentryCurrentDate.date dateByAddingTimeInterval:[retryAfterInSeconds doubleValue]];
        }
    }
    
    return rateLimits;
}

- (NSString *)removeAllWhitespaces:(NSString *)string {
    NSArray *words = [string componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [words componentsJoinedByString:@""];
}

- (NSNumber *)getRetryAfterInSeconds:(NSString *)string {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    return [numberFormatter numberFromString:string];
}

- (SentryRateLimitCategory)mapStringToCategory:(NSString *)category {
    SentryRateLimitCategory result = kSentryRateLimitCategoryUnkown;
    if ([category isEqualToString:@""]) {
        result = kSentryRateLimitCategoryAll;
    }
    if ([category isEqualToString:@"default"]) {
        result = kSentryRateLimitCategoryDefault;
    }
    if ([category isEqualToString:@"error"]) {
        result = kSentryRateLimitCategoryError;
    }
    if ([category isEqualToString:@"session"]) {
        result = kSentryRateLimitCategorySession;
    }
    if ([category isEqualToString:@"transaction"]) {
        result = kSentryRateLimitCategoryTransaction;
    }
    if ([category isEqualToString:@"attachment"]) {
        result = kSentryRateLimitCategoryAttachment;
    }
    return result;
}

@end

NS_ASSUME_NONNULL_END
