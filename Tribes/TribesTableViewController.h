//
//  TribesTableViewController.h
//  Tribes
//
//  Created by German Espitia on 1/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSwipeTableViewCell.h"
#import <iAd/iAd.h>


@interface TribesTableViewController : UITableViewController <ADBannerViewDelegate>

// public methods to call from signing up navigation stack
-(void)setUp;
-(void)UISetUp;
-(void)makeItRainConfetti;
@end
