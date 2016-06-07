//
//  AddFriendByUsernameTableViewController.h
//  Tribes
//
//  Created by German Espitia on 6/6/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <ParseUI/ParseUI.h>
#import "Tribe.h"

@interface AddFriendByUsernameTableViewController : PFQueryTableViewController
@property (nonatomic, strong) Tribe * tribe;

@end
