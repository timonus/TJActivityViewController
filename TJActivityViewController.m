//
//  TJActivityViewController.m
//
//  Created by Tim Johnsen on 1/1/15.
//  Copyright (c) 2015 Tim Johnsen. All rights reserved.
//

#import "TJActivityViewController.h"

#import <os/lock.h>

NSString *const TJActivityViewControllerFacebookRegexString = @"com\\.facebook\\.Facebook.*\\.ShareExtension";
NSString *const TJActivityViewControllerFacebookMessengerRegexString = @"com\\.facebook\\.(Messenger|Orca).*\\.ShareExtension";
NSString *const TJActivityViewControllerInstagramRegexString = @"com\\.(facebook|burbn)\\.(?i)instagram.*\\.shareextension";
NSString *const TJActivityViewControllerSnapchatActivityType = @"com.toyopagroup.picaboo.share";

@interface TJActivityItemProxy : UIActivityItemProvider

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlaceholderItem:(id)placeholderItem NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithItemSource:(id<UIActivityItemSource>)itemSource NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithItemProvider:(UIActivityItemProvider *)itemProvider NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) UIActivityViewController *activityViewController;

@end

@interface TJActivityViewController ()

@property (nonatomic, strong) NSMutableDictionary<BOOL (^)(NSString *activityType), void(^)(void)> *overrideBlocksForMatchBlocks;
@property (nonatomic, strong) NSMutableDictionary *itemBlocksForOverriddenActivityTypes;

@property (nonatomic, assign) BOOL hasHandledActivities;

@property (nonatomic, assign) os_unfair_lock *lock;

@end

@implementation TJActivityViewController

@dynamic completionHandler;

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    NSMutableArray<TJActivityItemProxy *> *const activityItemProxies = [NSMutableArray arrayWithCapacity:activityItems.count];
    for (const id activityItem in activityItems) {
        TJActivityItemProxy *proxy = nil;
        if ([activityItem isKindOfClass:[UIActivityItemProvider class]]) {
            proxy = [[TJActivityItemProxy alloc] initWithItemProvider:(UIActivityItemProvider *)activityItem];
        } else if ([activityItem conformsToProtocol:@protocol(UIActivityItemSource)]) {
            proxy = [[TJActivityItemProxy alloc] initWithItemSource:(id<UIActivityItemSource>)activityItem];
        } else {
            proxy = [[TJActivityItemProxy alloc] initWithPlaceholderItem:activityItem];
        }
        [activityItemProxies addObject:proxy];
    }
    
    if (self = [super initWithActivityItems:activityItemProxies applicationActivities:applicationActivities]) {
        [activityItemProxies makeObjectsPerformSelector:@selector(setActivityViewController:) withObject:self];
        self.overrideBlocksForMatchBlocks = [[NSMutableDictionary alloc] init];
        self.itemBlocksForOverriddenActivityTypes = [[NSMutableDictionary alloc] init];
        self.lock = malloc(sizeof(os_unfair_lock_t));
        *self.lock = OS_UNFAIR_LOCK_INIT;
    }
    
    return self;
}

- (void)dealloc
{
    free(self.lock);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Reset this in case the view controller is reused multiple times.
    self.hasHandledActivities = NO;
}

- (void)overrideActivityType:(NSString *)activityType withBlock:(void (^)(void))block
{
    NSParameterAssert(activityType);
    NSParameterAssert(block);
    
    [self.overrideBlocksForMatchBlocks setObject:block
                                          forKey:^BOOL (NSString *matchActivityType) {
                                              return [matchActivityType isEqualToString:activityType];
                                          }];
}

- (void)overrideActivityTypeMatchingRegex:(NSString *)regexString withBlock:(void (^)(void))block
{
    NSParameterAssert(regexString);
    NSParameterAssert(block);
    
    [self.overrideBlocksForMatchBlocks setObject:block
                                          forKey:^BOOL (NSString *matchActivityType) {
                                              return matchActivityType.length > 0 && [matchActivityType rangeOfString:regexString options:NSRegularExpressionSearch].location != NSNotFound;
                                          }];
}

- (void)overrideItemForActivityType:(NSString *)activityType withBlock:(id (^)(void))block
{
    NSParameterAssert(activityType);
    NSParameterAssert(block);
    
    [self.itemBlocksForOverriddenActivityTypes setObject:block forKey:activityType];
}

@end

@interface TJActivityItemProxy ()

// Mutually exclusive, one must be populated.
@property (nonatomic, strong) id<UIActivityItemSource> itemSource;
@property (nonatomic, strong) UIActivityItemProvider *itemProvider;

@end

@implementation TJActivityItemProxy

- (instancetype)initWithPlaceholderItem:(id)placeholderItem
{
    NSParameterAssert(placeholderItem);
    
    if (self = [super initWithPlaceholderItem:placeholderItem]) {
    }
    
    return self;
}

- (instancetype)initWithItemSource:(id<UIActivityItemSource>)itemSource
{
    NSParameterAssert(itemSource);
    
    if (self = [super initWithPlaceholderItem:[itemSource activityViewControllerPlaceholderItem:(_Nonnull id)nil]]) {
        self.itemSource = itemSource;
    }
    return self;
}

- (instancetype)initWithItemProvider:(UIActivityItemProvider *)itemProvider {
    NSParameterAssert(itemProvider);
    if (self = [super initWithPlaceholderItem:itemProvider.placeholderItem]) {
        self.itemProvider = itemProvider;
    }
    return self;
}

- (id)item
{
    TJActivityViewController *const overridableActivityViewController = [self.activityViewController isKindOfClass:[TJActivityViewController class]] ? (TJActivityViewController *)self.activityViewController : nil;
    
    id item = nil;
    
    __block void (^overrideBlock)(void) = nil;
    [overridableActivityViewController.overrideBlocksForMatchBlocks enumerateKeysAndObjectsUsingBlock:^(BOOL (^ _Nonnull matchBlock)(NSString *), void (^ _Nonnull replacementBlock)(void), BOOL * _Nonnull stop) {
        if (matchBlock(self.activityType)) {
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
            void (^dismissAndPerformOverrideBlock)(void) = ^{
                if (self.activityViewController.completionWithItemsHandler) {
                    self.activityViewController.completionWithItemsHandler(self.activityType, NO, nil, nil);
                }
                [self.activityViewController dismissViewControllerAnimated:YES completion:overrideBlock];
            };
            if ([NSThread isMainThread]) {
                dismissAndPerformOverrideBlock();
            } else {
                dispatch_async(dispatch_get_main_queue(), dismissAndPerformOverrideBlock);
            }
        }
    } else {
        id (^itemOverrideBlock)(void) = [overridableActivityViewController.itemBlocksForOverriddenActivityTypes objectForKey:self.activityType];
        if (itemOverrideBlock) {
            item = itemOverrideBlock();
        } else {
            // Fall back to the actual data.
            if (self.itemProvider) {
                item = self.itemProvider.item;
            } else if (self.itemSource) {
                item = [self.itemSource activityViewController:self.activityViewController itemForActivityType:self.activityType];
            }
            if (!item) {
                item = self.placeholderItem;
            }
        }
    }
    
    return item;
}

#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0

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
