//
//  AddFriendsTableViewController.h
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tribe.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>


@interface AddFriendsTableViewController : UITableViewController <UINavigationControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) Tribe * tribe;

@end
