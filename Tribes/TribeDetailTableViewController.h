//
//  TribeDetailTableViewController.h
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import "Parse.h"
#import "Habit.h"
#import "Tribe.h"

@interface TribeDetailTableViewController : PFQueryTableViewController

@property (atomic, strong) Habit * habit;
@property (atomic, strong) Tribe * tribe;

@end
