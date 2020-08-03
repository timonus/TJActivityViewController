//
//  TJActivityViewController.h
//
//  Created by Tim Johnsen on 1/1/15.
//  Copyright (c) 2015 Tim Johnsen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TJActivityViewControllerFacebookRegexString;
extern NSString *const TJActivityViewControllerFacebookMessengerRegexString;
extern NSString *const TJActivityViewControllerInstagramRegexString;
extern NSString *const TJActivityViewControllerSnapchatActivityType;

@interface TJActivityViewController : UIActivityViewController

/**
 Overrides a particular activity type with a block.
 @param activityType The activity type to override.
 @param block The block to execute in place of the given activity.
 */
- (void)overrideActivityType:(NSString *)activityType withBlock:(dispatch_block_t)block;

/**
 Overrides activity types matching a regex with a block.
 @param regexString A regex that the tapped @c activityType is matched with.
 @param block The block to execute in place of the given activity.
 */
- (void)overrideActivityTypeMatchingRegex:(NSString *)regexString withBlock:(dispatch_block_t)block;

/**
 Overrides the item used for a particular activity.
 @param activityType The activity type to override.
 @param block A block that returns the overriden item to use for the activity.
 */
- (void)overrideItemForActivityType:(NSString *)activityType withBlock:(id (^)(void))block;

#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0

/**
 Overrides the @c LPLinkMetadata that the activity view controller presents.
 */
@property (nonatomic) LPLinkMetadata *linkMetadata API_AVAILABLE(ios(13.0));

#endif

/// TJActivityViewController only supports @c completionWithItemsHandler, so this is explicitly marked as unavailable.
@property (nullable, nonatomic, copy) UIActivityViewControllerCompletionHandler completionHandler NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
