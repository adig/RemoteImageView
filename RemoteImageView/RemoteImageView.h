/**
 * RemoteImageView.h
 *
 * Copyright (c) 2012 Adrian Geana
 * Created by Adrian Geana on 5/23/12.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 */


#import <UIKit/UIKit.h>

typedef enum {
    RIDiskCacheMode,
    RIURLCacheMode,
    RICacheModeNone
} RICacheMode;

typedef void (^imageLoadCompleteBlock_t)(UIImage *image);
typedef void (^imageLoadErrorBlock_t)(NSError *error);
typedef void (^imageResizeBlock_t)(UIImage *inputImage, UIImage **outputImage);

@interface RemoteImageView : UIImageView

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) BOOL showActivityIndicator;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorStyle;
@property (nonatomic, assign) BOOL animate;
@property (nonatomic, assign) BOOL resizeImage;
@property (nonatomic, assign) BOOL ignoreAnimateOnCache;
@property (nonatomic, assign) RICacheMode cacheMode;

@property (nonatomic, strong) imageLoadCompleteBlock_t completeBlock;
@property (nonatomic, strong) imageLoadErrorBlock_t errorBlock;
@property (nonatomic, strong) imageResizeBlock_t imageResizeBlock;


/**
 Starts loading the URL provided right away and calls the result blocks on finish
 
 @param completeBlock - Block that will be called when the image is loaded successfully. Receives the UIImage as parameter.
 @param errorBlock - Block that will be called when an error occured. Receives NSError as parameter.
 */
- (void)loadImageURL:(NSURL *)imageURL
   withCompleteBlock:(imageLoadCompleteBlock_t)completeBlock
      withErrorBlock:(imageLoadErrorBlock_t)errorBlock;

/**
 Cancels current request operation (if not finished)
 */
- (void)cancel;

/**  
    Cleans out the disk cache directory. This will remove ALL images loaded with RemoteImageView
    ! deprecated, use clearCache istead
 */
+ (void)clearDiskCache DEPRECATED_ATTRIBUTE;


/**
 Cleans out all caches. This will remove ALL images loaded with RemoteImageView
    - Disk cache
    - NSURLCache
    - in-memory NSCache
 */
+ (void) clearCache;

/**
 Set / Get Default UIImage, used for all RemoteImageView instances when an request failes or result is not a valid image
 */
+ (UIImage *)defaultGlobalImage;
+ (void)setDefaultGlobalImage:(UIImage *)image;

/**
 Cancels all operations from the current queue (all RemoteImageView instances available)
 */
+ (void)cancelAll;

@end
