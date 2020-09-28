#import "SentryDefines.h"
#import "SentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(User)
@interface SentryUser : NSObject <SentrySerializable, NSCopying>

/**
 * Optional: Id of the user
 */
@property (nonatomic, copy) NSString *userId;

/**
 * Optional: Email of the user
 */
@property (nonatomic, copy) NSString *_Nullable email;

/**
 * Optional: Username
 */
@property (nonatomic, copy) NSString *_Nullable username;

/**
 * Optional: IP Address
 */
@property (nonatomic, copy) NSString *_Nullable ipAddress;

/**
 * Optional: Additional data
 */
@property (nonatomic, strong) NSDictionary<NSString *, id> *_Nullable data;

/**
 * Initializes a SentryUser with the id
 * @param userId NSString
 * @return SentryUser
 */
- (instancetype)initWithUserId:(NSString *)userId;

- (instancetype)init;
+ (instancetype)new NS_UNAVAILABLE;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToUser:(SentryUser *)user;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
