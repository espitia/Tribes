//
//  TribeMenuTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeMenuTableViewController.h"
#import "TribesTableViewController.h"
#import "MembersTableViewController.h"
#import "HabitsTableViewController.h"
#import "User.h"
#import "Habit.h"
#import "SCLAlertView.h"

@interface TribeMenuTableViewController () {
    UISwitch * privacySwitch;
}

@end

@implementation TribeMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set title of vc to tribe name
    self.navigationItem.title = _tribe[@"name"];

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // rows depend on what is being shown (members/habits)
    if (_tribe[@"admin"] == [User currentUser]) {
        return 3;
    } else {
        return 2;
    }
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID" forIndexPath:indexPath];
    
    NSString * title;
    switch (indexPath.row) {
        case 0:
            title = @"👫 Members";
            break;
        case 1:
            title = @"🏋 Habits";
            break;
        case 2:
            title = @"🔐 Private";
            [self configureCellForPrivacySettingWithCell:cell];
            break;
            
        default:
            break;
    }

    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
            
            
        case 0:
            [self performSegueWithIdentifier:@"ShowMembers" sender:_tribe];
            break;
        case 1:
            [self performSegueWithIdentifier:@"ShowHabits" sender:_tribe];
            break;
        case 2:
            [self showPrivacyExplainerAlert];
            break;
            
        default:
            break;
    }
}

#pragma mark - Configure Cell

-(void)configureCellForPrivacySettingWithCell:(UITableViewCell *)cell {
    
    privacySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = privacySwitch;
    
    privacySwitch.on = (_tribe.privacy) ? true : false;
    
    [privacySwitch addTarget:self action:@selector(handlePrivacySwitch:) forControlEvents:UIControlEventValueChanged];
}

-(void)handlePrivacySwitch:(UISwitch *)sender {
    UISwitch* switchControl = sender;
    _tribe.privacy = (switchControl.on) ? true : false;
    [_tribe saveEventually];
}

-(void)showPrivacyExplainerAlert {
    SCLAlertView * explainerAlert = [[SCLAlertView alloc] initWithNewWindow];
    [explainerAlert showInfo:@"Private 🔐" subTitle:@"Setting your Tribe on Private will allow others to join your Tribe only after you admit them. If your Tribe's Private setting is turned off, other members may join without being confirmed first." closeButtonTitle:@"GOT IT" duration:0.0];
}
#pragma mark - Segue navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"ShowMembers"]) {
        
        // get tribe VC to set the tribe
        MembersTableViewController * membersVC = segue.destinationViewController;

        // sender contains habit tapped
        membersVC.tribe = sender;
        
    } else if ([segue.identifier isEqualToString:@"ShowHabits"]) {
        
        
        // get tribe VC to set the tribe
        HabitsTableViewController * habitsVC = segue.destinationViewController;
        
        // sender contains habit tapped
        habitsVC.tribe = sender;
        
    }
}


@end
