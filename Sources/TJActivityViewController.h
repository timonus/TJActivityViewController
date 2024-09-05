//
//  TJActivityViewController.h
//
//  Created by Tim Johnsen on 1/1/15.
//  Copyright (c) 2015 Tim Johnsen. All rights reserved.
//

#import <UIKit/UIKit.h>

#define INCLUDE_RECIPIENTS 0

NS_ASSUME_NONNULL_BEGIN

typedef NSString *TJActivityTypeRegex;

extern TJActivityTypeRegex const TJActivityViewControllerFacebookRegexString;
extern TJActivityTypeRegex const TJActivityViewControllerFacebookMessengerRegexString;
extern TJActivityTypeRegex const TJActivityViewControllerInstagramRegexString;
extern UIActivityType const TJActivityViewControllerSnapchatActivityType;
extern TJActivityTypeRegex const TJActivityTypeSaveToCameraRollRegexString; // Compatible with Mac Catalyst
extern UIActivityType const TJActivityViewControllerTikTokActivityType;
extern UIActivityType const TJActivityViewControllerThreadsActivityType;
extern UIActivityType const TJActivityViewControllerRetroActivityType;

@interface TJActivityViewController : UIActivityViewController

/**
 Overrides a particular activity type with a block.
 @param activityType The activity type to override.
 @param block The block to execute in place of the given activity.
 */
- (void)overrideActivityType:(UIActivityType)activityType withBlock:(dispatch_block_t)block;
#if INCLUDE_RECIPIENTS
- (void)overrideActivityType:(UIActivityType)activityType includeSpecificShareRecipients:(const BOOL)includeSpecificShareRecipients withBlock:(dispatch_block_t)block;
#endif

/**
 Overrides activity types matching a regex with a block.
 @param regexString A regex that the tapped @c activityType is matched with.
 @param block The block to execute in place of the given activity.
 */
- (void)overrideActivityTypeMatchingRegex:(TJActivityTypeRegex)regexString withBlock:(void (^)(UIActivityType))block;
#if INCLUDE_RECIPIENTS
- (void)overrideActivityTypeMatchingRegex:(TJActivityTypeRegex)regexString includeSpecificShareRecipients:(const BOOL)includeSpecificShareRecipients withBlock:(void (^)(UIActivityType))block;
#endif

/**
 Overrides the item used for a particular activity.
 @param activityType The activity type to override.
 @param block A block that returns the overriden item to use for the activity.
 */
- (void)overrideItemForActivityType:(UIActivityType)activityType withBlock:(id (^)(void))block;

#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0

/**
 Overrides the @c LPLinkMetadata that the activity view controller presents.
 */
@property (nonatomic) LPLinkMetadata *linkMetadata API_AVAILABLE(ios(13.0));

#endif

/// TJActivityViewController only supports @c completionWithItemsHandler, so this is explicitly marked as unavailable.
@property (nullable, nonatomic, copy) UIActivityViewControllerCompletionHandler completionHandler NS_UNAVAILABLE;

#if INCLUDE_RECIPIENTS
@property (nonatomic, readonly) BOOL activityIncludesRecipient;
#endif

@end

NS_ASSUME_NONNULL_END
