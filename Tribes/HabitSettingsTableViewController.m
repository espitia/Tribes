//
//  HabitSettingsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 2/22/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "HabitSettingsTableViewController.h"
#import "TribeDetailTableViewController.h"
#import "SCLAlertView.h"
#import "User.h"

@interface HabitSettingsTableViewController () {
    BOOL editingDueTime;
    UIDatePicker * timePicker;
}

@end

@implementation HabitSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Settings 🔧";
}

-(void)willMoveToParentViewController:(UIViewController *)parent {
    
    // if moving back to habit detail vc
    if (![parent isEqual:self.parentViewController]) {
        
        // get habitdetailvc (tribesdetail same thing) and reload data to reflect settings change
        UINavigationController * navController = (UINavigationController *)self.parentViewController;
        TribeDetailTableViewController * tribesVc = (TribeDetailTableViewController *)navController.viewControllers[1];
        [tribesVc.tableView reloadData];
    }
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            [self formatHibernationCell:cell];
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // deselect cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    // show alert explainers
    
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    
    switch (indexPath.row) {
        case 0:
            [alert showQuestion:@"🐻 Hibernation" subTitle:@"When you hibernate, you are taking a rest for the day. Other Tribe members won't send you motivation so you can relax 😎" closeButtonTitle:@"OK" duration:0.0];
            break;

        default:
            break;
    }
    
    
}

#pragma mark - Formatting cells

-(void)formatHibernationCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"🐻 Hibernation";

    UISwitch * hibernationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = hibernationSwitch;
    
    hibernationSwitch.on = (_activity.hibernation) ? true : false;

    [hibernationSwitch addTarget:self action:@selector(handleHibernationSwitch:) forControlEvents:UIControlEventValueChanged];
    
}

#pragma mark - Handle actions

-(void)handleHibernationSwitch:(UISwitch *)sender {
    
    UISwitch* switchControl = sender;
    
    
    _activity.hibernation = (switchControl.on) ? true : false;
    [_activity saveEventually];
    
    // add local notification to remove hibernation on the next day
    if (_activity.hibernation) {
        [_activity makeHibernationNotification];
    } else {
        [_activity deleteHibernationNotification];
    }
}




@end
