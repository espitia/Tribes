//
//  TribeDetailTableViewController.h
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse.h"
#import "Habit.h"

@interface TribeDetailTableViewController : UITableViewController

@property (atomic, strong) Habit * habit;

@end
