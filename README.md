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


#TODO 
* cancel functionality
* in-memory cache support
* smarter disk caching support (follow cache headers, cache large image as well)
* configurable image resize modes
* ...
