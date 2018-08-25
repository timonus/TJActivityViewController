//
//  TJActivityViewController.m
//
//  Created by Tim Johnsen on 1/1/15.
//  Copyright (c) 2015 Tim Johnsen. All rights reserved.
//

#import "TJActivityViewController.h"

@interface TJActivityItemProxy : NSObject <UIActivityItemSource>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPlaceholderItem:(id)placeholderItem NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithItemSource:(id<UIActivityItemSource>)itemSource NS_DESIGNATED_INITIALIZER;

@end

@interface TJActivityViewController ()

@property (nonatomic, strong) NSMutableDictionary<BOOL (^)(NSString *activityType), void(^)(void)> *overrideBlocksForMatchBlocks;
@property (nonatomic, strong) NSMutableDictionary *itemBlocksForOverriddenActivityTypes;

@property (nonatomic, assign) BOOL hasHandledActivities;

@end

@implementation TJActivityViewController

@dynamic completionHandler;

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities
{
    NSMutableArray<TJActivityItemProxy *> *const activityItemProxies = [NSMutableArray arrayWithCapacity:activityItems.count];
    for (const id activityItem in activityItems) {
        TJActivityItemProxy *proxy = nil;
        if ([activityItem conformsToProtocol:@protocol(UIActivityItemSource)]) {
            proxy = [[TJActivityItemProxy alloc] initWithItemSource:(id<UIActivityItemSource>)activityItem];
        } else {
            proxy = [[TJActivityItemProxy alloc] initWithPlaceholderItem:activityItem];
        }
        [activityItemProxies addObject:proxy];
    }
    
    if (self = [super initWithActivityItems:activityItemProxies applicationActivities:applicationActivities]) {
        self.overrideBlocksForMatchBlocks = [[NSMutableDictionary alloc] init];
        self.itemBlocksForOverriddenActivityTypes = [[NSMutableDictionary alloc] init];
    }
    
    return self;
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
@property (nonatomic, strong) id placeholderItem;
@property (nonatomic, strong) id<UIActivityItemSource> itemSource;

@end

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
    
    __block void (^overrideBlock)(void) = nil;
    [overridableActivityViewController.overrideBlocksForMatchBlocks enumerateKeysAndObjectsUsingBlock:^(BOOL (^ _Nonnull matchBlock)(NSString *), void (^ _Nonnull replacementBlock)(void), BOOL * _Nonnull stop) {
        if (matchBlock(activityType)) {
            overrideBlock = replacementBlock;
            *stop = YES;
        }
    }];
    
    if (overrideBlock) {
        BOOL canRunBlock = YES;
        if (overridableActivityViewController) {
            // Ensure override blocks aren't invoked multiple times.
            @synchronized(overridableActivityViewController) {
                if (overridableActivityViewController.hasHandledActivities) {
                    canRunBlock = NO;
                } else {
                    overridableActivityViewController.hasHandledActivities = YES;
                }
            }
        }
        if (canRunBlock) {
            // If this activity type is overridden, call the override block on the main thread
            void (^dismissAndPerformOverrideBlock)(void) = ^{
                if (activityViewController.completionWithItemsHandler) {
                    activityViewController.completionWithItemsHandler(activityType, NO, nil, nil);
                }
                [activityViewController dismissViewControllerAnimated:YES completion:overrideBlock];
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
    
    return item;
}

@end
