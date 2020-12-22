# TJActivityViewController

`TJActivityViewController` is a handy subclass of [`UIActivityViewController`](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller?language=objc) that allows you to override actions easily without implementing [`UIActivityItemSource`](https://developer.apple.com/documentation/uikit/uiactivityitemsource?language=objc).

## Usage

You can override a particular activity or one matching a regex with a block using the following methods:

```objc
UIImage *imageToShare = /* ... */;
TJActivityViewController *viewController = [[TJActivityViewController alloc] initWithActivityItems:@[imageToShare] applicationActivities:nil];

// Override Facebook sharing with a block.
[viewController overrideActivityType:UIActivityTypePostToTwitter withBlock:^{
    // Launch a custom Twitter share action.
}];

// Override actions matching a regex.
[viewController overrideActivityTypeMatchingRegex:@"com\\.foo\\.bar\\..*" withBlock:^{
    // Custom sharing actions.
}];
```

You can also override the item that's passed to a particular activity with a block using the following method:

```objc
// TJActivityViewControllerSnapchatActivityType and a few others are provided for convenience
[viewController overrideItemForActivityType:TJActivityViewControllerSnapchatActivityType // Snapchat's share extension	
                                  withBlock:^id {
	return /* a 9:16 image cropped just for Snapchat. */;
}];
```

In iOS 13 and above, you can set the [link preview](https://developer.apple.com/videos/play/wwdc2019/262/?t=301) on an instance of `TJActivityViewController` using the `linkMetadata` property.

```objc
LPLinkMetadata *linkMetadata = [LPLinkMetadata new];
linkMetadata.title = @"My Cool Link";
linkMetadata.imageProvider = /* an image provider for your link preview */;
activityViewController.linkMetadata = linkMetadata;
```

## Why

While `UIActivityItemSource` is a powerful API for sharing through `UIActivityViewController`, it's a bit cumbersome to use and has limitations when it comes to overriding actions. Many products now have custom sharing SDKs that are more powerful than their built-in share extensions, but developers who use `UIActivityViewController` are forced into using the less powerful share extensions.

Some developers have taken to building their own bespoke sharing menus to work around this limitation of `UIActivityViewController`, but that leads to fragmented and incomplete sharing experiences across products. `TJActivityViewController` gives you the best of both worlds: you get to use the standard iOS share menu, and can still customize sharing options with your own special touches.

For a more detailed blog post on the subject, see [here](https://medium.com/p/f24410308699).

## About

I originally wrote `TJActivityViewController` for [Close-up](https://closeup.wtf) and have since also used it in [Burst](http://theburstapp.com). If you decide to use `TJActivityViewController` [let me know](https://twitter.com/timonus)!
