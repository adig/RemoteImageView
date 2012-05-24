//
//  FirstViewController.m
//  RemoteImageViewDemo
//
//  Created by Adrian Geana on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FirstViewController.h"
#import "RemoteImageView.h"

#define REMOTE_IMAGE_VIEW_TAG 102
#define TITLE_LABEL_TAG 103

@interface FirstViewController () {
    NSArray *_imageList;
}
@end

@implementation FirstViewController

@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"TableView", @"TableView");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
        _imageList = [NSArray arrayWithObjects:@"http://farm8.static.flickr.com/7086/7044898577_97445ea260.jpg",
                                            @"http://farm8.static.flickr.com/7138/7047749565_8b20628acf.jpg",
                                            @"http://farm8.static.flickr.com/7196/7070072209_d1f393c797.jpg",
                                            @"http://farm8.static.flickr.com/7272/7071326439_a16c53092c.jpg",
                                            @"http://farm8.static.flickr.com/7279/7073096965_f5392cbd9e.jpg",
                                            @"http://farm8.static.flickr.com/7189/7091087059_37824d10de.jpg",
                                            @"http://farm8.static.flickr.com/7233/7098322101_c77ac97dfa.jpg",
                                            @"http://farm8.static.flickr.com/7071/7105582489_73a0aa9b74.jpg",
                                            @"http://farm8.static.flickr.com/7132/7113300435_26a77ddc4a.jpg",
                                            @"http://farm8.static.flickr.com/7184/7121785089_40e969da0f.jpg",
                                            @"http://farm9.static.flickr.com/8009/7142179315_633aa6db7d.jpg",
                                            @"http://farm8.static.flickr.com/7239/7171902074_2d9b462d9c.jpg",
                                            @"http://farm6.static.flickr.com/5236/7182691108_4f3635a83d.jpg",
                                            @"http://farm8.static.flickr.com/7100/7216746262_3e5fffe975.jpg",
                                            @"http://farm1.static.flickr.com/42/91957795_5a27611762.jpg",
                                            @"http://farm1.static.flickr.com/33/63452603_b3a5b5448d.jpg",
                                            @"http://farm1.static.flickr.com/100/317184224_fffde7547e.jpg",
                                            @"http://farm2.static.flickr.com/1156/942938486_65b6d1efe7.jpg",
                                            @"http://farm1.static.flickr.com/28/41942696_ac7de727a7.jpg",
                                            @"http://farm1.static.flickr.com/27/45599281_0e33a17e35.jpg", nil];
        
    }
    return self;
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    self.tableView = nil;
}

#pragma mark UITableViewDataSource

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
}


#pragma mark UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"exampleCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    RemoteImageView *imageView;
    UILabel *titleLabel;
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        imageView = [[RemoteImageView alloc] initWithFrame:CGRectMake(10, 5, 60, 60)];
        imageView.tag = REMOTE_IMAGE_VIEW_TAG;
        [cell.contentView addSubview:imageView];
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 5, 200, 60)];
        titleLabel.font = [UIFont systemFontOfSize:16.0f];
        titleLabel.tag = TITLE_LABEL_TAG;
        [cell.contentView addSubview:titleLabel];
        
    } else {
        imageView = (RemoteImageView *)[cell.contentView viewWithTag:REMOTE_IMAGE_VIEW_TAG];
        titleLabel = (UILabel *)[cell.contentView viewWithTag:TITLE_LABEL_TAG];
    }
    
    imageView.imageURL = [NSURL URLWithString:[_imageList objectAtIndex:indexPath.row]];
    titleLabel.text = [NSString stringWithFormat:@"Image %d", indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
