/**
 * RemoteImageView.m
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

#import "RemoteImageView.h"
#import <CommonCrypto/CommonHMAC.h>


#define UIViewAutoresizingFlexibleMargins           \
        UIViewAutoresizingFlexibleBottomMargin    | \
        UIViewAutoresizingFlexibleLeftMargin      | \
        UIViewAutoresizingFlexibleRightMargin     | \
        UIViewAutoresizingFlexibleTopMargin

#define IMAGE_CACHE_DIRECTORY @"RemoteImageViewCache"

#define URL_CACHE_MEMORY_CAPACITY 50 * 1048576 

@interface RemoteImageView(){
    UIActivityIndicatorView *_activityIndicator;
    NSBlockOperation *_loadingOperation;
}
@end

#pragma mark UIImage Additions

@interface UIImage (RemoteImageResize)
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
@end

static UIImage *_globalDefaultImage;
static NSOperationQueue *_imageLoadingQueue;
static NSCache *_imageCache;

@implementation RemoteImageView

@synthesize imageURL = _imageURL;
@synthesize showActivityIndicator = _showActivityIndicator;
@synthesize activityIndicatorStyle = _activityIndicatorStyle;
@synthesize resizeImage = _resizeImage;
@synthesize animate = _animate;
@synthesize completeBlock = _completeBlock;
@synthesize errorBlock = _errorBlock;
@synthesize imageResizeBlock = _imageResizeBlock;
@synthesize ignoreAnimateOnCache = _ignoreAnimateOnCache;
@synthesize cacheMode = _cacheMode;

+ (void)initialize {
  
    _imageLoadingQueue = [[NSOperationQueue alloc] init];
    _imageLoadingQueue.maxConcurrentOperationCount = 20;
    _imageCache = [[NSCache alloc] init];
    _imageCache.name = @"RemoteImageView_imageCache";
}

- (id)init {
    
    if(self = [super init]) {
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if(self = [super initWithCoder:aDecoder]) {
        [self customInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:URL_CACHE_MEMORY_CAPACITY];
    
    _animate = YES;
    _resizeImage = YES;
    _showActivityIndicator = YES;
    _ignoreAnimateOnCache = NO;
    _cacheMode = RIDiskCacheMode;
    _activityIndicatorStyle = UIActivityIndicatorViewStyleGray;
    self.autoresizesSubviews = YES;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] 
                                                  initWithActivityIndicatorStyle:_activityIndicatorStyle];
    
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.hidden = YES;
    activityIndicator.frame = CGRectMake(round((self.frame.size.width - 
                                                activityIndicator.frame.size.width) / 2), 
                                         round((self.frame.size.height -
                                                activityIndicator.frame.size.height) / 2), 
                                         activityIndicator.frame.size.width, 
                                         activityIndicator.frame.size.height);
    [self addSubview:activityIndicator];
    
    _activityIndicator = activityIndicator;
}


#pragma mark Public Methods

- (void)setImageURL:(NSURL *)imageURL {
    
    [self cancel];
    
    self.image = nil;
    
    imageURL = [self parseImageURL:imageURL];
    
    _imageURL = imageURL;
    
    if(!imageURL) return;
    
    [self startActivityIndicator];
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        
        if([weakOperation isCancelled]) {
            return;
        }
        
        CGSize imageSize =_resizeImage ? CGSizeMake(self.frame.size.width, self.frame.size.height) :
                                        CGSizeZero;
        UIImage *resultImage = [self getCachedImageForURL:imageURL size:imageSize];
        
        if(resultImage) {
            
            [self announceSuccess:resultImage forURL:imageURL fromCache:YES];            
            return;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL
                                                 cachePolicy:_cacheMode != RIDiskCacheMode ? NSURLRequestReloadIgnoringCacheData :
                                                                                             NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:60.0];
        NSURLResponse *response;
        NSError *error;
        NSData *result = [NSURLConnection sendSynchronousRequest:request 
                                               returningResponse:&response 
                                                           error:&error];
        
        if(error) {
            
            [self announceError:error forURL:imageURL];
            
        } else {
            
            resultImage = [[UIImage alloc] initWithData:result];
            
            if(!resultImage && _globalDefaultImage) {
                resultImage = _globalDefaultImage;
            }
            
            resultImage = [self getResizedImage:resultImage];
            
            [self announceSuccess:resultImage forURL:imageURL fromCache:NO];
            
            [self cacheImage:resultImage forURL:imageURL];
        }
    }];
    
    _loadingOperation = operation;
    [_imageLoadingQueue addOperation:_loadingOperation];
}

- (void)loadImageURL:(NSURL *)imageURL 
   withCompleteBlock:(imageLoadCompleteBlock_t)completeBlock 
      withErrorBlock:(imageLoadErrorBlock_t)errorBlock {
    
    self.completeBlock = completeBlock;
    self.errorBlock = errorBlock;
    
    self.imageURL = imageURL;
}

- (void)cancel {
    
    [_loadingOperation cancel];
}

- (UIImage *)getResizedImage:(UIImage *)image {
    
    UIImage *resizedImage;
    
    if(_resizeImage) {
        
        if(_imageResizeBlock) {
            
            _imageResizeBlock(image, &resizedImage);
            
        } else {
            resizedImage = [image imageByScalingAndCroppingForSize:CGSizeMake(self.frame.size.width,
                                                                                    self.frame.size.height)];
        }
        
    } else {
        resizedImage = image;
    }
    
    return resizedImage;
    
}

#pragma mark Result handling

- (void)announceSuccess:(UIImage *)image forURL:(NSURL *)imageURL fromCache:(BOOL)fromCache {
    
    if(imageURL != _imageURL) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.image = image;
        
        if(_completeBlock)
            _completeBlock(image);
        
        [self stopActivityIndicator];
        
        if(_animate && (!fromCache || (fromCache && !_ignoreAnimateOnCache))) {
            self.alpha = 0;
            [UIView animateWithDuration:0.2 animations:^(){
                self.alpha = 1.0f;
            }];
        }
        
    });
}

- (void)announceError:(NSError *)error forURL:(NSURL *)imageURL {
    
    if(imageURL != _imageURL) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self stopActivityIndicator];
        
        if(_globalDefaultImage) {
            self.image = _globalDefaultImage;
        }
        
        if(_errorBlock)
            _errorBlock(error);
    });
}

- (NSURL *)parseImageURL:(NSURL *)imageURL {
    
    if(!imageURL) return imageURL;
    
    NSString *newURLString = [imageURL.absoluteString stringByReplacingOccurrencesOfString:@":width"
                                                                                withString:[@(self.frame.size.width * [UIScreen mainScreen].scale) stringValue]];
    newURLString = [newURLString stringByReplacingOccurrencesOfString:@":height"
                                                                      withString:[@(self.frame.size.height * [UIScreen mainScreen].scale) stringValue]];
    return [NSURL URLWithString:newURLString];
}


#pragma mark ActivityIndicator

- (void)startActivityIndicator {

    if(_showActivityIndicator && _activityIndicator.hidden == YES) {
        _activityIndicator.hidden = NO;
        _activityIndicator.activityIndicatorViewStyle = _activityIndicatorStyle;
        [_activityIndicator startAnimating];
    }
}

- (void)stopActivityIndicator {
    [_activityIndicator stopAnimating];
}


#pragma mark Cache helpers

- (void)cacheImage:(UIImage *)image forURL:(NSURL *)url {
    
    CGSize imageSize = _resizeImage ? CGSizeMake(self.frame.size.width, self.frame.size.height) : CGSizeZero;
    if(image) [_imageCache setObject:image forKey:[RemoteImageView pathForURL:url size:imageSize]];
    
    if(_cacheMode == RIDiskCacheMode) {
        NSString *imagePath = [RemoteImageView pathForURL:url size:imageSize];
        [UIImagePNGRepresentation(image) writeToFile:imagePath options:NSDataWritingAtomic error:nil];
    }
}

- (UIImage *)getCachedImageForURL:(NSURL *)url size:(CGSize)size {
    
    UIImage *resultImage = [_imageCache objectForKey:[RemoteImageView pathForURL:url size:size]];
    
    if(resultImage) return resultImage;
    
    if(_cacheMode == RIDiskCacheMode) {
        
        NSString *imagePath = [RemoteImageView pathForURL:url
                                                     size:size];
        resultImage = [UIImage imageWithContentsOfFile:imagePath];
        
    } else if(_cacheMode == RIURLCacheMode) {
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
        resultImage =[UIImage imageWithData:cachedResponse.data];
        
        // NSURLCache saves images at full size
        if(resultImage) {
            resultImage = [self getResizedImage:resultImage];
        }
    }
    
    if(resultImage) [_imageCache setObject:resultImage forKey:[RemoteImageView pathForURL:url size:size]];
    
    return resultImage;
}

+ (NSString *) pathForURL:(NSURL *)url size:(CGSize)size {
    
    NSString *urlString = [url absoluteString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [RemoteImageView cacheDirectoryPath];
    
    if(![fileManager fileExistsAtPath:path]) {
        
        [fileManager createDirectoryAtPath:path 
               withIntermediateDirectories:YES 
                                attributes:nil 
                                     error:nil];
    }
    
    if ([[urlString substringFromIndex:[urlString length]-1] isEqualToString:@"/"]) {
        urlString = [urlString substringToIndex:[urlString length]-1];
    }
    
    const char *cStr = [urlString UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSString *urlKey =[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                       result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], 
                       result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
    
    urlKey = [urlKey stringByAppendingFormat:@"_%@", CGSizeEqualToSize(size, CGSizeZero) ? 
                            @"FULL" : [NSString stringWithFormat:@"%.0f_%.0f", size.width, size.height]];
    
    NSString *imagePath = [[RemoteImageView cacheDirectoryPath]  stringByAppendingPathComponent:urlKey];
    return imagePath;
}

+ (NSString *) cacheDirectoryPath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:IMAGE_CACHE_DIRECTORY];
    return path;
}

+ (void)clearDiskCache_ {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [RemoteImageView cacheDirectoryPath];
    NSDirectoryEnumerator* en = [fileManager enumeratorAtPath:path];
    NSError* err = nil;
    BOOL res;
    
    NSString* file;
    while (file = [en nextObject]) {
        res = [fileManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"error: %@", err);
        }
    }
}

+ (void) clearDiskCache {
    [RemoteImageView clearDiskCache_];
}

+ (void) clearCache {
    
    [RemoteImageView clearDiskCache_];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [_imageCache removeAllObjects];
}

#pragma mark Global Default image

+ (void)setDefaultGlobalImage:(UIImage *)image {
    
    _globalDefaultImage = image;
}

+(UIImage *)defaultGlobalImage  {
    
    return _globalDefaultImage;
}

#pragma mark cancelAll

+ (void)cancelAll {
    
    [_imageLoadingQueue cancelAllOperations];
}

@end


#pragma mark UIImage resize Additions

@implementation UIImage (RemoteImageResize)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;        
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)  {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        } else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        } else if (widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) 
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

@end
