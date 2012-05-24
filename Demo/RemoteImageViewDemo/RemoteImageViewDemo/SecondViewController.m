//
//  SecondViewController.m
//  RemoteImageViewDemo
//
//  Created by Adrian Geana on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

@synthesize imageView = _imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"CachingDemo", @"CachingDemo");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    _imageView.activityIndicatorStyle = UIActivityIndicatorViewStyleWhiteLarge;
	[self loadImage:[NSURL URLWithString:@"http://farm8.static.flickr.com/7233/7098322101_c77ac97dfa.jpg"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.imageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark Action handling

-(IBAction)didChangeSegmentValue:(id)sender {
    
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    if(segmentedControl.selectedSegmentIndex == 0) {
        [self loadImage:[NSURL URLWithString:@"http://farm8.static.flickr.com/7233/7098322101_c77ac97dfa.jpg"]];
    } else if(segmentedControl.selectedSegmentIndex == 1) {
        [self loadImage:[NSURL URLWithString:@"http://farm1.static.flickr.com/100/317184224_fffde7547e.jpg"]];
    } else if(segmentedControl.selectedSegmentIndex == 2) {
        [self loadImage:[NSURL URLWithString:@"http://farm1.static.flickr.com/27/45599281_0e33a17e35.jpg"]];
    }
}

-(IBAction)didTapClearCacheButton:(id)sender {
    
    [RemoteImageView clearDiskCache];
}

- (void)loadImage:(NSURL *)imageURL {
    
    [_imageView loadImageURL:imageURL withCompleteBlock:^(UIImage *image){
        NSLog(@"Did load image : %@", image); 
    } withErrorBlock:^(NSError *error) {
        NSLog(@"Did fail loading image : %@", error);
    }];
    
}

@end
