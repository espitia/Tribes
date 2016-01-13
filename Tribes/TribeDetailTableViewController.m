//
//  TribeDetailTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeDetailTableViewController.h"

@interface TribeDetailTableViewController () {
    NSMutableArray * members;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // load members of the tribe
    [self loadMembersOfTribe];
    
    // init instance variables
    members = [[NSMutableArray alloc] init];
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
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeMemberCell" forIndexPath:indexPath];
    
    
    return cell;
}


#pragma mark - Helper methods

-(void)loadMembersOfTribe {
    
    // get relation of tribe object to the members
    PFRelation * membersOfTribeRelation = _tribe[@"members"];
    
    // query that relation for the objects (members)
    PFQuery * queryForMembersOfTribe = [membersOfTribeRelation query];
    [queryForMembersOfTribe findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [members addObjectsFromArray:objects];
            
        } else {
            NSLog(@"error: %@", error);
        }
    }];
    
}

@end
