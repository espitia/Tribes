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
        [self makeHibernationNotification];
    } else {
        [self deleteHibernationNotification];
    }
}

-(void)makeHibernationNotification {
    
    // if other habits have set hibernation, dont allow for creation of more notifications
    if ([self hibernationNotificationAlreadySet])
        return;
    
    // fire date (tomorrow 10am)
    NSDate* now = [NSDate date] ;
    NSDateComponents* tomorrowComponents = [NSDateComponents new] ;
    tomorrowComponents.day = 1 ;
    NSCalendar* calendar = [NSCalendar currentCalendar] ;
    NSDate* tomorrow = [calendar dateByAddingComponents:tomorrowComponents toDate:now options:0] ;
    NSDateComponents* tomorrowAt10AMComponents = [calendar components:(NSCalendarUnitDay|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:tomorrow] ;
    tomorrowAt10AMComponents.hour = 10;
    NSDate* tomorrowAt10AM = [calendar dateFromComponents:tomorrowAt10AMComponents] ;
    
    // make local notificaiton to take it off the next day
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = tomorrowAt10AM;
    localNotification.repeatInterval = NSCalendarUnitDay;
    localNotification.category = @"HIBERNATION_RESPONSE";
    localNotification.alertBody = @"🐻 It's a new day! Would you like to turn hibernations off?";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    NSLog(@"sceduel notif: %@", [[UIApplication sharedApplication] scheduledLocalNotifications]);
}

-(void)deleteHibernationNotification {
    
    // if other habits have hibernation, dont remove
    if ([self otherHabitsHaveHibernationOn])
        return;
    
    // if no other habit has hibernation on, remove it
    for (UILocalNotification * notificaiton in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([notificaiton.category isEqualToString:@"HIBERNATION_RESPONSE"]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notificaiton];
        }
    }
}

-(BOOL)hibernationNotificationAlreadySet {
    for (UILocalNotification * notificaiton in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([notificaiton.category isEqualToString:@"HIBERNATION_RESPONSE"]) {
            return true;
        }
    }
    return false;
}
-(BOOL)otherHabitsHaveHibernationOn {
    for (Activity * activity in [User currentUser].activities) {
        if (activity.hibernation) {
            return true;
        }
    }
    return false;
}
@end
