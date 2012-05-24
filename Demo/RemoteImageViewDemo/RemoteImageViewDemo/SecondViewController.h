//
//  SecondViewController.h
//  RemoteImageViewDemo
//
//  Created by Adrian Geana on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RemoteImageView.h"

@interface SecondViewController : UIViewController

@property (nonatomic, strong) IBOutlet RemoteImageView *imageView;

- (IBAction)didChangeSegmentValue:(id)sender;
- (IBAction)didTapClearCacheButton:(id)sender;

@end
