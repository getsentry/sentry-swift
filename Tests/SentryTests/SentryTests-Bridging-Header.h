//
//  Use this file to import your target's public headers that you would like to
//  expose to Swift.
//
#import "NSData+SentryCompression.h"
#import "NSDate+SentryExtras.h"
#import "SentryAttachment.h"
#import "SentryAutoSessionTrackingIntegration.h"
#import "SentryBreadcrumbTracker.h"
#import "SentryClient+Private.h"
#import "SentryClient+TestInit.h"
#import "SentryConcurrentRateLimitsDictionary.h"
#import "SentryCrashAdapter.h"
#import "SentryCrashBinaryImageProvider.h"
#import "SentryCrashC.h"
#import "SentryCrashDefaultBinaryImageProvider.h"
#import "SentryCrashDefaultMachineContextWrapper.h"
#import "SentryCrashInstallationReporter.h"
#import "SentryCrashIntegration+TestInit.h"
#import "SentryCrashIntegration.h"
#import "SentryCrashMachineContext.h"
#import "SentryCrashReportSink.h"
#import "SentryCrashReportStore.h"
#import "SentryCrashStackEntryMapper.h"
#import "SentryCrashUUIDConversion.h"
#import "SentryCurrentDate.h"
#import "SentryDateUtil.h"
#import "SentryDebugMeta.h"
#import "SentryDebugMetaBuilder.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDefaultRateLimits.h"
#import "SentryDispatchQueueWrapper.h"
#import "SentryDsn.h"
#import "SentryEnvelopeItemType.h"
#import "SentryEnvelopeRateLimit.h"
#import "SentryFileContents.h"
#import "SentryFileManager+TestProperties.h"
#import "SentryFileManager.h"
#import "SentryFrameInAppLogic.h"
#import "SentryFrameRemover.h"
#import "SentryHttpDateParser.h"
#import "SentryHttpTransport.h"
#import "SentryHub+Private.h"
#import "SentryHub+TestInit.h"
#import "SentryId.h"
#import "SentryInstallation.h"
#import "SentryLevelMapper.h"
#import "SentryLog+TestInit.h"
#import "SentryLog.h"
#import "SentryLogOutput.h"
#import "SentryMeta.h"
#import "SentryMigrateSessionInit.h"
#import "SentryNSError.h"
#import "SentryNSURLRequest.h"
#import "SentryRateLimitCategory.h"
#import "SentryRateLimitCategoryMapper.h"
#import "SentryRateLimitParser.h"
#import "SentryRateLimits.h"
#import "SentryRetryAfterHeaderParser.h"
#import "SentrySDK+Private.h"
#import "SentryScope+Private.h"
#import "SentrySdkInfo.h"
#import "SentrySerialization.h"
#import "SentrySession+Private.h"
#import "SentrySessionTracker.h"
#import "SentrySpanId.h"
#import "SentryStacktraceBuilder.h"
#import "SentrySystemEventsBreadcrumbs.h"
#import "SentryTestIntegration.h"
#import "SentryThreadInspector.h"
#import "SentryTransport.h"
#import "SentryTransportFactory.h"
#import "SentryUserFeedback.h"
