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
    UISwitch * hibernationSwitch;
    UISwitch * watcherSwitch;
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
    return 2;
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
        case 1:
            [self formatWatcherCell:cell];
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
        case 1:
            [alert showQuestion:@"👀 Watcher" subTitle:@"When you are a watcher, you are not expected to take part in doing the habit. All you are asked to do is to motivate and keep those who are accountable! ✊" closeButtonTitle:@"OK" duration:0.0];
            break;

        default:
            break;
    }
    
    
}

#pragma mark - Formatting cells

-(void)formatHibernationCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"🐻 Hibernation";

    hibernationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = hibernationSwitch;
    
    hibernationSwitch.on = (_activity.hibernation) ? true : false;

    [hibernationSwitch addTarget:self action:@selector(handleHibernationSwitch:) forControlEvents:UIControlEventValueChanged];
    
}

-(void)formatWatcherCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"👀 Watcher";
    
    watcherSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = watcherSwitch;
    
    watcherSwitch.on = (_activity.watcher) ? true : false;
    
    [watcherSwitch addTarget:self action:@selector(handleWatcherSwitch:) forControlEvents:UIControlEventValueChanged];
    
}

#pragma mark - Handle actions

-(void)handleHibernationSwitch:(UISwitch *)sender {
    
    UISwitch* switchControl = sender;

    _activity.hibernation = (switchControl.on) ? true : false;
    [_activity saveEventually];
    
    // add local notification to remove hibernation on the next day
    if (_activity.hibernation) {
        
        // turn off watcher setting (if you are hibernating you are active in habit)
        if (_activity.watcher) {
            _activity.watcher = false;
            [_activity saveEventually];
            [watcherSwitch setOn:false];
        }
        
        [_activity makeHibernationNotification];
    } else {
        [_activity deleteHibernationNotification];
    }

}

-(void)handleWatcherSwitch:(UISwitch *)sender {
    
    UISwitch* switchControl = sender;
    
    _activity.watcher = (switchControl.on) ? true : false;
    
    if (_activity.watcher && _activity.hibernation) {
        _activity.hibernation = false;
        [hibernationSwitch setOn:false];
    }
    [_activity saveEventually];
        
    
    
}




@end
