//
//  SettingsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 2/22/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SCLAlertView.h"

@interface SettingsTableViewController () {
    BOOL editingDueTime;
    UIDatePicker * timePicker;
}

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Settings 🔧";
    editingDueTime = (_activity.dueTime) ? true : false;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == 2 && editingDueTime) { // this is my picker cell
        return 219;
    }
    return self.tableView.rowHeight;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            [self formatHibernationCell:cell];
            break;
        case 1:
            [self formatTimeSwitchCell:cell];
            break;
        case 2:
            [self formatTimePickerCell:cell];
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
            [alert showInfo:@"🐻 Hibernation" subTitle:@"When you hibernate, you are taking a rest for the day. Other Tribe members won't send you motivation so you can relax 😎" closeButtonTitle:@"OK" duration:0.0];
            break;
        case 1:
            [alert showInfo:@"🕐 Due Time" subTitle:@"Setting a due time for your tribe tells other tribe members that you will do your activity after said time. Until then, you won't receive any motivation." closeButtonTitle:@"OK" duration:0.0];            break;
            
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

-(void)formatTimeSwitchCell:(UITableViewCell *)cell {
    cell.textLabel.text = @"🕐 Due time";
    
    UISwitch * dueTimeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = dueTimeSwitch;
    
    dueTimeSwitch.on = (_activity.dueTime) ? true : false;
    
    [dueTimeSwitch addTarget:self action:@selector(handleDueTimeSwitch:) forControlEvents:UIControlEventValueChanged];

}

-(void)formatTimePickerCell:(UITableViewCell *)cell {

    if (!editingDueTime)
        return;
    
    if (!timePicker) {
        timePicker = [[UIDatePicker alloc] initWithFrame:cell.contentView.frame];
        timePicker.datePickerMode = UIDatePickerModeTime;
        [cell.contentView addSubview:timePicker];
        [timePicker addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
        if (_activity.dueTime) {
            timePicker.date = _activity.dueTime;
        } else {
            _activity.dueTime = timePicker.date;
            [_activity saveInBackground];
        }
    }
}

#pragma mark - Handle actions

-(void)handleHibernationSwitch:(UISwitch *)sender {
    
    UISwitch* switchControl = sender;
    
    _activity.hibernation = (switchControl.on) ? true : false;
    [_activity saveInBackground];
}

-(void)handleDueTimeSwitch:(UISwitch *)sender {
    
    UISwitch* switchControl = sender;
    
    _activity.dueTime = (switchControl.on) ? timePicker.date : nil;
    [_activity saveInBackground];
    
    editingDueTime = !editingDueTime;
    
    [UIView animateWithDuration:.4 animations:^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }];
}

-(void)timeChanged:(UIDatePicker *)sender {
    _activity.dueTime = sender.date;
    [_activity saveInBackground];
}
-(void)updateTribeData {
    NSUInteger tribeVC = self.navigationController.viewControllers.count;
    tribeVC -= 2;
    UITableViewController * vc = [self.navigationController.viewControllers objectAtIndex:tribeVC];
    [vc.tableView reloadData];
}
@end
