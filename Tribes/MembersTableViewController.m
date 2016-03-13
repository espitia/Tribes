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
@interface MembersTableViewController ()

@end

@implementation MembersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set vc title
    self.navigationItem.title = @"Members 👫";
    
    // right button to create Tribe
    UIBarButtonItem * addMemberButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addMember)];
    [self.navigationItem setRightBarButtonItem:addMemberButton];
   
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
    return _tribe.tribeMembers.count;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberCell" forIndexPath:indexPath];
    
    User * member = [_tribe.tribeMembers objectAtIndex:indexPath.row];
    cell.textLabel.text = member[@"username"];
    
    return cell;
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
