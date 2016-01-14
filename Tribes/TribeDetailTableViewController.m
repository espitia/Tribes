//
//  TribeDetailTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeDetailTableViewController.h"

@interface TribeDetailTableViewController () {
    NSMutableArray * membersAndActivities;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // load members of the tribe
//    [self loadMembersOfTribe];
    
    // init instance variables
    membersAndActivities = [[NSMutableArray alloc] init];

    membersAndActivities = [_tribe loadMembersOfTribeWithActivitiesWithBlock:^{
        [self.tableView reloadData];
    }];
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





@end
