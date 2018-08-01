# TJActivityViewController

`TJActivityViewController` is a handy subclass of [`UIActivityViewController`](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller?language=objc) that allows you to override actions easily without implementing [`UIActivityItemSource`](https://developer.apple.com/documentation/uikit/uiactivityitemsource?language=objc).

## Usage

You can override a particular activity (or activity matching a regex) with a block using the following methods.

```
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

You can also override the item that's passed to a particular activity with a block using the following method.

```
[viewController overrideItemForActivityType:@"com.toyopagroup.picaboo.share" // Snapchat's share extension	
                                  withBlock:^id {
	return /* a 9:16 image cropped just for Snapchat. */;
}];
```

## Why

While `UIActivityItemSource` is a powerful API for sharing through `UIActivityViewController`, it's a bit cumbersome to use and has limitations when it comes to overriding actions. Many products now have custom sharing SDKs that are as powerful or more powerful that their built-in share extensions, but developers who use `UIActivityViewController` are forced into using other app's share extensions. Some developers have taken to building their own bespoke sharing menus to work around this limitation of `UIActivityViewController`, but that leads to fragmented and incomplete sharing experiences across products. `TJActivityViewController` gives you the best of both worlds, you get to use the standard iOS share menu but customize the sharing options you'd like have special touches for.

For a more detailed blog post on the subject, see [here](https://medium.com/p/f24410308699).

## About

I originally wrote `TJActivityViewController` for [Close-up](https://closeup.wtf) and have since also used it in [Burst](http://theburstapp.com). If you decide to use `TJActivityViewController` [let me know](https://twitter.com/timonus)!
