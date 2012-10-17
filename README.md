**RemoteImageView** is a easy to use, fast, configurable replacement for `UIImageView` that handles loading  remote pictures.

# Features
* iOS 4.3+ compatible (should work on iOS 4.0 without major issues)
* ARC ready
* uses GCD
* Resize & center crop before setting to `image`
* Disk caching for resized images

# How To Install 
1. Copy `RemoteImageView.h` and `RemoteImageView.m` into your project folder and add them to your project
2. Import `RemoteImageView.h` : 
		
		#import "RemoteImageView.h"
3. You're ready to use ! 


# Basic Usage
**RemoteImagteView** is build as a `UIIImageView` compatible replacement. 

	RemoteImageView *imageView = [[RemoteImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
	imageView.imageURL = [NSURL URLWithString:@"http://farm9.staticflickr.com/8025/7260272478_95198c7452_z.jpg"];
	[self.view addSubview:imageView];
	
This will create an `UIImageView` component and start loading the url right away. The result image will be scaled and center cropped :

![Loading Steps](http://i.imgur.com/k86Bu.png)

*(Dog Image Credits : [stovak on Flickr](http://www.flickr.com/photos/stovak/7260272478/))*

#Options
* **resizeImage (BOOL)** - default `YES`. If set to `NO` the image will not be resized and cropped 
* **animate (BOOL)** - default `YES`. Animates the alpha of the image from 0 to 1 on load
* **ignoreAnimateOnCache (BOOL)** - default `NO`. Doesn't run the display animation if image data comes from cache (example : in a `UITableView` when scrolling)
* **CacheMode (RICacheMode)** - default `RIDiskCacheMode` 
	* `RIDiskCacheMode` - caches all images on disk and loads them from disk on subsequent requests. Cache is persisted between application sessions
	* `RIURLCacheMode` - uses default `NSURLCache` for caching. Cache is not persisted between application sessions.
* **showActivityIndicator (BOOL)** - default `YES`. Shows an centered activity indicator while URL is loading. Conforms to `activityIndicatorStyle` property.
* **activityIndicatorStyle (UIActivityIndicatorViewStyle)** - default `UIActivityIndicatorViewStyleGray`. Style to use for activity indicator shown when `showActivityIndicator` is set to `YES` and image is loading.


#Handling result
**RemoteImageView** can let you know when the loading is finished. This is done by passing a complete and error block to the component. The result blocks are always called on the main dispatch queue. 

    RemoteImageView *imageView = [[RemoteImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    imageView.completeBlock = ^(UIImage *image) {
    
        NSLog(@"image finished loading : %@", image);
        
    };
    imageView.errorBlock = ^(NSError *error) {
    
        NSLog(@"image failed to load with error : %@", error);
        
    };
	imageView.imageURL = [NSURL URLWithString:@"http://farm9.staticflickr.com/8025/7260272478_95198c7452_z.jpg"];
    [self.view addSubview:imageView];

For similar functionality you can use the following convenience method :  

    RemoteImageView *imageView = [[RemoteImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    [imageView loadImageURL:[NSURL URLWithString:@"http://farm9.staticflickr.com/8025/7260272478_95198c7452_z.jpg"] 
          withCompleteBlock:^(UIImage *image) {
          
        NSLog(@"image finished loading : %@", image);
        
    }   withErrorBlock:^(NSError *error){
    
        NSLog(@"image failed to load with error : %@", error);
        
    }];
    [self.view addSubview:imageView];
    
#Caching
All images loaded by a **RemoteImageView** instance are saved in the `Cache` directory and loaded from there on subsequent requests. 
You can invalidate the disk cache by calling : 
	
	[RemoteImageView clearDiskCache];

#Cancel loading
You can cancel loading for a specific `RemoteImageView` instance by calling the instance method `cancel` : 
    
    [myImageView cancel];
    
Or you can cancel all loading operations in all active `RemoteImageView` instances by calling the class method `cancelAll` :
 
	[RemoteImageView cancelAll];
	

#Default fallback image

If you want to use a default fallback image for requests that have failed you can set it using the `setDefaultGlobalImage:` class method :

	[RemoteImageView setDefaultGlobalImage:[UIImage imageNamed:@"404"]];
	
You can get the default global image by using the `defaultGlobalImage` class method : 

	UIImage *defaultImage = [RemoteImageView defaultGlobalImage];


#Custom Image Resizing
You can fully customize the loaded image before displaying it by using the `imageResizeBlock` property. If the property is not set the default image resize mode is used (scale, crop and center). 

**Note** : This property is ignored if `resizeImage` is set to `NO`

Example (let's say you have an `UIImage` category that implements the `resizedImage:(CGSize)size` method ) : 

	RemoteImageView *imageView = [[RemoteImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
	imageView.imageResizeBlock = ^(UIImage *input, UIImage **output) {
        UIImage *resized = [input resizedImage:imageView.frame.size];
        *output = resized;
    };
	imageView.imageURL = [NSURL URLWithString:@"http://farm9.staticflickr.com/8025/7260272478_95198c7452_z.jpg"];
	[self.view addSubview:imageView];
	

#TODO 
* smarter disk caching support (follow cache headers, cache large image as well)
* configurable image resize modes
* ...
