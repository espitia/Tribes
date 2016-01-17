//
//  TribeDetailTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeDetailTableViewController.h"
#import "AddFriendsTableViewController.h"

@interface TribeDetailTableViewController () {
    NSMutableArray * membersAndActivities;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init instance variables
    membersAndActivities = [[NSMutableArray alloc] init];

    // load members and activities [this should be done in main table to cut down on idle time]
    membersAndActivities = [_tribe loadMembersOfTribeWithActivitiesWithBlock:^{
        [self.tableView reloadData];
    }];
    
    // right button to Add friends
    [self addRightButton];
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
    return membersAndActivities.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeMemberCell" forIndexPath:indexPath];
   
    // dictionary with member (PFUser)and acitivty key (Activity object)
    NSDictionary * member = membersAndActivities[indexPath.row];
    cell.textLabel.text = member[@"member"][@"username"];
    cell.detailTextLabel.text = member[@"activity"][@"objectId"];
    
    return cell;
}

#pragma mark - Helper methods

-(void)addFriends {
    
    [self performSegueWithIdentifier:@"AddFriends" sender:nil];
    
//    // Objective-C
//    DGTSession *userSession = [Digits sharedInstance].session;
//    DGTContacts *contacts = [[DGTContacts alloc] initWithUserSession:userSession];
//    
//    [contacts startContactsUploadWithCompletion:^(DGTContactsUploadResult *result, NSError *error) {
//        // Inspect results and error objects to determine if upload succeeded.
//    }];
}

-(void)addRightButton {
    UIBarButtonItem * createTribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Add Friends" style:UIBarButtonItemStylePlain target:self action:@selector(addFriends)];
    [self.navigationItem setRightBarButtonItem:createTribeButton];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier  isEqual: @"AddFriends"]) {
        AddFriendsTableViewController * vc = (AddFriendsTableViewController *)segue.destinationViewController;
        vc.tribe = _tribe;
    }
}

@end
