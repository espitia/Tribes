//
//  AddHabitTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddHabitTableViewController.h"
#import "User.h"
#import "SCLAlertView.h"
#import <Crashlytics/Crashlytics.h>

@interface AddHabitTableViewController () {
    User * currentUser;
    UITextField * habitNameTextField;
    UIBarButtonItem * createHabitButton;
}

@end

@implementation AddHabitTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to create Tribe
    createHabitButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createTribe)];
    [self.navigationItem setRightBarButtonItem:createHabitButton];
    
    // set current user
    currentUser = [User currentUser];
    
    // initialize textfield
    habitNameTextField = [[UITextField alloc] init];
    
    self.tableView.rowHeight = 100;
}

-(void)viewDidAppear:(BOOL)animated {
    [habitNameTextField becomeFirstResponder];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Add Habits to your Tribe:";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HabitCell" forIndexPath:indexPath];
    
    
    // add uitextfield for name fo tribe
    CGRect activityNameFrame = CGRectMake(15,
                                          cell.frame.origin.y - 30,
                                          cell.frame.size.width,
                                          cell.frame.size.height);
    [habitNameTextField setFrame:activityNameFrame];
    habitNameTextField.placeholder = @"e.g. Read 📚";
    [habitNameTextField setFont:[UIFont systemFontOfSize:40]];
    [cell.contentView addSubview:habitNameTextField];
    
    
    return cell;
}

#pragma mark - Stuff

-(void)createTribe {
    
    // disable button to not allow duplicates
    createHabitButton.enabled = false;
    if (![habitNameTextField.text isEqualToString:@""]) {
        
        // resign keyboard so alert doesn't show with it
        [habitNameTextField resignFirstResponder];

        // alert user that habit is being created
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        [alert showWaiting:@"Creating habit..." subTitle:@"🔧🔧🔧" closeButtonTitle:nil duration:0.0];
        
        [_tribe addHabitToTribeWithName:habitNameTextField.text andBlock:^(bool success) {
            if (success) {
                
                // log event
                [Answers logCustomEventWithName:@"Added habit" customAttributes:@{@"success":@true}];
                
                [_tribe updateTribeWithBlock:^(bool success) {
                    if (success) {
                        [alert hideView];
                        [self.navigationController popToRootViewControllerAnimated:true];
                    } else {
                        SCLAlertView * errorAddingHabit = [[SCLAlertView alloc] initWithNewWindow];
                        [errorAddingHabit showError:@"Oh oh!" subTitle:@"There was an error adding the habit. Please try again." closeButtonTitle:@"OK" duration:0.0];
                    }
                }];
            } else {
                
                // log event
                [Answers logCustomEventWithName:@"Add habit" customAttributes:@{@"success":@false}];
                
                SCLAlertView * errorAddingHabit = [[SCLAlertView alloc] initWithNewWindow];
                [errorAddingHabit showError:@"Oh oh!" subTitle:@"There was an error adding the habit. Please try again." closeButtonTitle:@"OK" duration:0.0];
            }
        }];
        
        
    } else {
        
        [habitNameTextField resignFirstResponder];
        
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        [alert addButton:@"OK" actionBlock:^{
            [habitNameTextField becomeFirstResponder];
            createHabitButton.enabled = true;
        }];
        [alert showError:@"❌" subTitle:@"Make sure your Habit has a name" closeButtonTitle:nil duration:0.0];
    }
    
}


@end
