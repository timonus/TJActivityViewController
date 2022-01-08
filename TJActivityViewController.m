//
//  TJActivityViewController.m
//
//  Created by Tim Johnsen on 1/1/15.
//  Copyright (c) 2015 Tim Johnsen. All rights reserved.
//

#import "TJActivityViewController.h"

#import <os/lock.h>

TJActivityTypeRegex const TJActivityViewControllerFacebookRegexString = @"(com\\.facebook\\.Facebook.*\\.ShareExtension|com\\.apple\\.UIKit\\.activity\\.PostToFacebook)";
TJActivityTypeRegex const TJActivityViewControllerFacebookMessengerRegexString = @"com\\.facebook\\.(Messenger|Orca).*\\.ShareExtension";
TJActivityTypeRegex const TJActivityViewControllerInstagramRegexString = @"com\\.(facebook|burbn)\\.(?i)instagram.*\\.shareextension";
UIActivityType const TJActivityViewControllerSnapchatActivityType = @"com.toyopagroup.picaboo.share";
TJActivityTypeRegex const TJActivityTypeSaveToCameraRollRegexString = @"com\\.apple\\.(UIKit\\.activity\\.SaveToCameraRoll|share\\.System\\.add-to-iphoto)";
UIActivityType const TJActivityViewControllerTikTokActivityType = @"com.zhiliaoapp.musically.ShareExtension";

@interface TJActivityItemProxy : NSObject <UIActivityItemSource>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlaceholderItem:(id)placeholderItem NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithItemSource:(id<UIActivityItemSource>)itemSource NS_DESIGNATED_INITIALIZER;

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@interface TJActivityViewController ()

@property (nonatomic) NSMutableDictionary<BOOL (^)(UIActivityType activityType, BOOL activityIncludesRecipient), void (^)(UIActivityType)> *overrideBlocksForMatchBlocks;
@property (nonatomic) NSMutableDictionary *itemBlocksForOverriddenActivityTypes;

#if INCLUDE_RECIPIENTS
@property (nonatomic) BOOL activityIncludesRecipient;
#endif
@property (nonatomic) BOOL hasHandledActivities;

@property (nonatomic) os_unfair_lock *lock;

@property (nonatomic) BOOL threadsafeIsPresented;

@end

@implementation TJActivityViewController

@dynamic completionHandler;

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    NSMutableArray<TJActivityItemProxy *> *const activityItemProxies = [NSMutableArray arrayWithCapacity:activityItems.count];
    for (const id activityItem in activityItems) {
        TJActivityItemProxy *proxy = nil;
        // Cheaper than -conformsToProtocol: per https://twitter.com/invalidname/status/1333528812177514497
        if ([activityItem respondsToSelector:@selector(activityViewControllerPlaceholderItem:)] && [activityItem respondsToSelector:@selector(activityViewController:itemForActivityType:)]) {
            proxy = [[TJActivityItemProxy alloc] initWithItemSource:(id<UIActivityItemSource>)activityItem];
        } else {
            proxy = [[TJActivityItemProxy alloc] initWithPlaceholderItem:activityItem];
        }
        [activityItemProxies addObject:proxy];
    }
    
    if (self = [super initWithActivityItems:activityItemProxies applicationActivities:applicationActivities]) {
        self.overrideBlocksForMatchBlocks = [NSMutableDictionary new];
        self.itemBlocksForOverriddenActivityTypes = [NSMutableDictionary new];
        self.lock = malloc(sizeof(os_unfair_lock_t));
        *self.lock = OS_UNFAIR_LOCK_INIT;
        
#if INCLUDE_RECIPIENTS
        // Determining if there are recipients is an exercise left to the reader.
#endif
    }
    
    return self;
}

- (void)dealloc
{
    free(self.lock);
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(dispatch_block_t)completion
{
    // Reset this in case the view controller is reused multiple times.
    if (!self.presentedViewController) {
        self.hasHandledActivities = NO;
    }
    
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.threadsafeIsPresented = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.threadsafeIsPresented = NO;
}

- (void)overrideActivityType:(UIActivityType)activityType withBlock:(dispatch_block_t)block
#if INCLUDE_RECIPIENTS
{
    [self overrideActivityType:activityType includeSpecificShareRecipients:NO withBlock:block];
}

- (void)overrideActivityType:(UIActivityType)activityType includeSpecificShareRecipients:(const BOOL)includeSpecificShareRecipients withBlock:(dispatch_block_t)block
#endif
{
    NSParameterAssert(activityType);
    NSParameterAssert(block);
    
    [self.overrideBlocksForMatchBlocks setObject:^(UIActivityType activityType) {
        block();
    }
                                          forKey:^BOOL (UIActivityType matchActivityType, BOOL activityIncludesRecipient) {
        return [matchActivityType isEqualToString:activityType]
#if INCLUDE_RECIPIENTS
        && (!activityIncludesRecipient || includeSpecificShareRecipients)
#endif
        ;
    }];
}

- (void)overrideActivityTypeMatchingRegex:(TJActivityTypeRegex)regexString withBlock:(void (^)(UIActivityType))block
#if INCLUDE_RECIPIENTS
{
    [self overrideActivityTypeMatchingRegex:regexString includeSpecificShareRecipients:NO withBlock:block];
}

- (void)overrideActivityTypeMatchingRegex:(TJActivityTypeRegex)regexString includeSpecificShareRecipients:(const BOOL)includeSpecificShareRecipients withBlock:(void (^)(UIActivityType))block
#endif
{
    NSParameterAssert(regexString);
    NSParameterAssert(block);
    
    [self.overrideBlocksForMatchBlocks setObject:block
                                          forKey:^BOOL (UIActivityType matchActivityType, BOOL activityIncludesRecipient) {
        return matchActivityType.length > 0 && [matchActivityType rangeOfString:regexString options:NSRegularExpressionSearch].location != NSNotFound
#if INCLUDE_RECIPIENTS
        && (!activityIncludesRecipient || includeSpecificShareRecipients)
#endif
        ;
    }];
}

- (void)overrideItemForActivityType:(UIActivityType)activityType withBlock:(id (^)(void))block
{
    NSParameterAssert(activityType);
    NSParameterAssert(block);
    
    [self.itemBlocksForOverriddenActivityTypes setObject:block forKey:activityType];
}

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@interface TJActivityItemProxy ()

// Mutually exclusive, one must be populated.
@property (nonatomic) id placeholderItem;
@property (nonatomic) id<UIActivityItemSource> itemSource;

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@implementation TJActivityItemProxy

- (instancetype)initWithPlaceholderItem:(id)placeholderItem
{
    NSParameterAssert(placeholderItem);
    
    if (self = [super init]) {
        self.placeholderItem = placeholderItem;
    }
    
    return self;
}

- (instancetype)initWithItemSource:(id<UIActivityItemSource>)itemSource
{
    NSParameterAssert(itemSource);
    
    if (self = [super init]) {
        self.itemSource = itemSource;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return self.placeholderItem ?: [self.itemSource activityViewControllerPlaceholderItem:activityViewController];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType
{
    TJActivityViewController *const overridableActivityViewController = [activityViewController isKindOfClass:[TJActivityViewController class]] ? (TJActivityViewController *)activityViewController : nil;
    
    id item = nil;
    
    if (overridableActivityViewController.threadsafeIsPresented) {
        __block void (^overrideBlock)(UIActivityType) = nil;
        const BOOL activityIncludesRecipient =
#if INCLUDE_RECIPIENTS
        overridableActivityViewController.activityIncludesRecipient
#else
        NO
#endif
        ;
        
        [overridableActivityViewController.overrideBlocksForMatchBlocks enumerateKeysAndObjectsUsingBlock:^(BOOL (^ _Nonnull matchBlock)(UIActivityType, BOOL), void (^ _Nonnull replacementBlock)(UIActivityType), BOOL * _Nonnull stop) {
            if (matchBlock(activityType, activityIncludesRecipient)) {
                overrideBlock = replacementBlock;
                *stop = YES;
            }
        }];
        
        if (overrideBlock) {
            BOOL canRunBlock = YES;
            if (overridableActivityViewController) {
                // Ensure override blocks aren't invoked multiple times.
                os_unfair_lock_lock(overridableActivityViewController.lock);
                
                if (overridableActivityViewController.hasHandledActivities) {
                    canRunBlock = NO;
                } else {
                    overridableActivityViewController.hasHandledActivities = YES;
                }
                
                os_unfair_lock_unlock(overridableActivityViewController.lock);
            }
            if (canRunBlock) {
                // If this activity type is overridden, call the override block on the main thread
                dispatch_block_t dismissAndPerformOverrideBlock = ^{
                    if (activityViewController.completionWithItemsHandler) {
                        activityViewController.completionWithItemsHandler(activityType, NO, nil, nil);
                    }
                    if (activityViewController.presentingViewController) {
                        [activityViewController dismissViewControllerAnimated:YES completion:^{
                            [activityViewController dismissViewControllerAnimated:YES completion:^{
                                overrideBlock(activityType);
                            }];
                        }];
                    } else {
                        [activityViewController dismissViewControllerAnimated:YES completion:^{
                            overrideBlock(activityType);
                        }];
                    }
                    
                };
                if ([NSThread isMainThread]) {
                    dismissAndPerformOverrideBlock();
                } else {
                    dispatch_async(dispatch_get_main_queue(), dismissAndPerformOverrideBlock);
                }
            }
        } else {
            id (^itemOverrideBlock)(void) = [overridableActivityViewController.itemBlocksForOverriddenActivityTypes objectForKey:activityType];
            if (itemOverrideBlock) {
                item = itemOverrideBlock();
            } else {
                // Otherwise just return the placeholder item
                item = self.placeholderItem ?: [self.itemSource activityViewController:activityViewController itemForActivityType:activityType];
            }
        }
    } else {
        // Calls for UIActivityTypeCopyToPasteboard sometimes come in before the view controller is presented for the link preview.
        // We don't want to inadvertently trigger an override in that case.
        item = self.placeholderItem;
    }
    
    return item;
}

#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0

- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController API_AVAILABLE(ios(13.0))
{
    TJActivityViewController *const overridableActivityViewController = [activityViewController isKindOfClass:[TJActivityViewController class]] ? (TJActivityViewController *)activityViewController : nil;
    LPLinkMetadata *metadata = overridableActivityViewController.linkMetadata;
    if (!metadata && [self.itemSource respondsToSelector:@selector(activityViewControllerLinkMetadata:)]) {
        metadata = [self.itemSource activityViewControllerLinkMetadata:activityViewController];
    }
    return metadata;
}

#endif

@end
