//
//  MembersTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "MembersTableViewController.h"
#import "AddFriendsTableViewController.h"
#import "User.h"
#import "SCLAlertView.h"
@interface MembersTableViewController ()

@end

@implementation MembersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set vc title
    self.navigationItem.title = @"Members 👫";
    
    // right button to create Tribe
    if ([[User currentUser] isAdmin:_tribe]) {
        UIBarButtonItem * addMemberButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addMember)];
        [self.navigationItem setRightBarButtonItem:addMemberButton];
    }

}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}

-(void)addMember {
    [self performSegueWithIdentifier:@"AddMember" sender:_tribe];
    
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribe.tribeMembers.count + _tribe.onHoldMembers.count;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberCell" forIndexPath:indexPath];
    
    // read users who are on hold first
    if (indexPath.row < _tribe.onHoldMembers.count) {
        User * member = [_tribe.onHoldMembers objectAtIndex:indexPath.row];
        cell.textLabel.text = member[@"username"];
        cell.detailTextLabel.text = @"👆 Tap to accept or decline";
    }
    // read regular members
    else {
        User * member = [_tribe.tribeMembers objectAtIndex:indexPath.row - _tribe.onHoldMembers.count];
        cell.textLabel.text = member[@"username"];
        cell.detailTextLabel.text = @"";
    }
    
    
    return cell;
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    // make sure user is tapping on 'on hold member'
    if (_tribe.onHoldMembers.count && indexPath.row < _tribe.onHoldMembers.count) {
        
        // on hold user to be confirmed
        User * member = [_tribe.onHoldMembers objectAtIndex:indexPath.row];
        
        // build alert
        SCLAlertView * confirmOnHoldMemberAlert = [[SCLAlertView alloc] initWithNewWindow];
        [confirmOnHoldMemberAlert addButton:@"CONFIRM" actionBlock:^{
            [_tribe confirmOnHoldUser:member withBlock:^(BOOL *success) {
                if (success) {
                    
                    [_tribe updateTribeWithBlock:^(bool success) {
                        if (success) {
                            // hide confirmation alert
                            [confirmOnHoldMemberAlert hideView];
                            
                            // show success alert (friend added)
                            SCLAlertView * successAlert = [[SCLAlertView alloc ] initWithNewWindow];
                            NSString * successAlertMessage = [NSString stringWithFormat:@"%@ has been added to %@", member[@"username"], _tribe[@"name"]];
                            [successAlert addButton:@"AWESOME" actionBlock:^{
                                [self.navigationController popToRootViewControllerAnimated:true];
                            }];
                            [successAlert showSuccess:@"Success 😃" subTitle:successAlertMessage closeButtonTitle:nil duration:0.0];
                        }
                    }];
       
                } else {
                    
                    // failed to add friend
                    [confirmOnHoldMemberAlert hideView];
                    
                    SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [errorAlert showError:@"Oh oh... 😬" subTitle:@"There was an error adding your buddy to the Tribe. Check your connect and try again!" closeButtonTitle:@"OK" duration:0.0];
                }
            }];
        }];
        [confirmOnHoldMemberAlert addButton:@"DECLINE" actionBlock:^{
            [_tribe declineOnHoldUser:member];
            [_tribe.onHoldMembers removeObject:member];
            [self.tableView reloadData];
        }];
        
        // build message string

        NSString * confirmMessage = [NSString stringWithFormat:@"Woud you like to accept %@ to %@?", member[@"username"], _tribe[@"name"]];
        
        // show alert
        [confirmOnHoldMemberAlert showInfo:@"Accept new member?" subTitle:confirmMessage closeButtonTitle:@"DECIDE LATER" duration:0.0];
        
    }
}

#pragma mark - Segue navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"AddMember"]) {
        
        // get tribe VC to set the tribe
        AddFriendsTableViewController * addMemberVC = segue.destinationViewController;
        
        // sender contains habit tapped
        addMemberVC.tribe = sender;
        
    } 
}
@end
