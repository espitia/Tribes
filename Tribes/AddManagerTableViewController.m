//
//  AddManagerTableViewController.m
//  Tribes
//
//  Created by German Espitia on 4/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddManagerTableViewController.h"
#import "AddMemberOrHabitMenuTableViewController.h"
#import "User.h"

@interface AddManagerTableViewController () {
    BOOL addMember;
}

@end

@implementation AddManagerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // if user doesn't belong to any tribes, don't show options to add a member/habit to tribes
    return ([User currentUser].tribes.count == 0) ? 2 : 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.row) {
        case 0:
            title = @"Create or join a Tribe 🙌";
            break;
        case 1:
            title = @"Add a member 👫";
            break;
        case 2:
            title = @"Add a Habit 🏋";
            break;
            
        default:
            break;
    }
    // Configure the cell...
    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    switch (indexPath.row) {
        case 0:
            // create/join tribe
            [self performSegueWithIdentifier:@"createTribe" sender:nil];
            break;
        case 1:
            // add a member
            addMember = true; // bool to tell next vc to add member or habit to tribe
            [self performSegueWithIdentifier:@"AddMemberOrHabit" sender:nil];
            break;
        case 2:
            // add a habit
            addMember = false; // bool to tell next vc to add member or habit to tribe
            [self performSegueWithIdentifier:@"AddMemberOrHabit" sender:nil];
            break;
            
        default:
            break;
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddMemberOrHabit"]) {
        AddMemberOrHabitMenuTableViewController * vc = (AddMemberOrHabitMenuTableViewController *)segue.destinationViewController;
        vc.addMember = addMember;
    }
}
@end
