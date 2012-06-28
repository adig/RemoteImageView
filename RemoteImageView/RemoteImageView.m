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
#import <QuartzCore/QuartzCore.h>


#define UIViewAutoresizingFlexibleMargins           \
        UIViewAutoresizingFlexibleBottomMargin    | \
        UIViewAutoresizingFlexibleLeftMargin      | \
        UIViewAutoresizingFlexibleRightMargin     | \
        UIViewAutoresizingFlexibleTopMargin

#define IMAGE_CACHE_DIRECTORY @"RemoteImageViewCache"

@interface RemoteImageView(){
    UIActivityIndicatorView *_activityIndicator;
    NSBlockOperation *_loadingOperation;
    CALayer *_imageLayer;
}
@end

#pragma mark UIImage Additions

@interface UIImage (RemoteImageResize)
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
@end

static UIImage *_globalDefaultImage;
static NSOperationQueue *_imageLoadingQueue;

@implementation RemoteImageView

@synthesize imageURL = _imageURL;
@synthesize showActivityIndicator = _showActivityIndicator;
@synthesize activityIndicatorStyle = _activityIndicatorStyle;
@synthesize resizeImage = _resizeImage;
@synthesize animate = _animate;
@synthesize completeBlock = _completeBlock;
@synthesize errorBlock = _errorBlock;
@synthesize imageResizeBlock = _imageResizeBlock;

+ (void)initialize {
  
    _imageLoadingQueue = [[NSOperationQueue alloc] init];
    _imageLoadingQueue.maxConcurrentOperationCount = 20;
    
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
    
    _animate = YES;
    _resizeImage = YES;
    _showActivityIndicator = YES;
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
    _imageLayer.contents = nil;
    _imageURL = imageURL;
    
    if(!imageURL) return;
    
    [self startActivityIndicator];
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __unsafe_unretained NSBlockOperation *weakOperation = operation;
    [operation addExecutionBlock:^{
        
        if([weakOperation isCancelled]) {
            return;
        }
        
        NSString *imagePath = [RemoteImageView pathForURL:imageURL 
                                                 size:_resizeImage ? CGSizeMake(self.frame.size.width, self.frame.size.height) : 
                                                                     CGSizeZero]; 
        UIImage *resultImage = [UIImage imageWithContentsOfFile:imagePath];
        
        if(resultImage) {
            [self announceSuccess:resultImage forURL:imageURL];
            return;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
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
            
            if(_resizeImage) {
                
                UIImage *resizedImage;
                
                if(_imageResizeBlock) {
                    
                    _imageResizeBlock(resultImage, &resizedImage);
                    
                } else {
                    resizedImage = [resultImage imageByScalingAndCroppingForSize:CGSizeMake(self.frame.size.width, 
                                                                                           self.frame.size.height)];
                }
                
                resultImage = resizedImage;
            } 
            
            [self announceSuccess:resultImage forURL:imageURL];
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
    // YOON - Nur
    [_loadingOperation cancel];
}

#pragma mark Result handling

- (void)announceSuccess:(UIImage *)image forURL:(NSURL *)imageURL {
    
    if(imageURL != _imageURL) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //self.image = image;
        if(!_imageLayer){
            _imageLayer = [CALayer layer];
            _imageLayer.frame = self.frame;
            [self.layer addSublayer:_imageLayer];
        }
        _imageLayer.contents = (id)image.CGImage;
        
        if(_completeBlock)
            _completeBlock(image);
        
        [self stopActivityIndicator];
        
        if(_animate) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = [NSNumber numberWithDouble:0.0];
            animation.toValue = [NSNumber numberWithDouble:1.0];
            animation.duration = 0.2;
            [_imageLayer addAnimation:animation forKey:@"fadeIn"];
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
    NSString *imagePath = [RemoteImageView pathForURL:url size:imageSize];
    [UIImagePNGRepresentation(image) writeToFile:imagePath options:NSDataWritingAtomic error:nil];
    
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

+ (void) clearDiskCache {
    
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

