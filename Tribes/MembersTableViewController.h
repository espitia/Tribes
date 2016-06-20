//
//  MembersTableViewController.h
//  Tribes
//
//  Created by German Espitia on 3/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import "Tribe.h"

@interface MembersTableViewController : PFQueryTableViewController
@property (nonatomic, strong) Tribe * tribe;

@end
