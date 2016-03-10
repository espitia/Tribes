//
//  TribeMenuTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeMenuTableViewController.h"
#import "AddFriendsTableViewController.h"
#import "AddHabitTableViewController.h"
#import "User.h"
#import "Habit.h"

@interface TribeMenuTableViewController ()

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
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID" forIndexPath:indexPath];

    
    return cell;
}





#pragma mark - Segue navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"AddFriends"]) {
        
        // get tribe VC to set the tribe
        AddFriendsTableViewController * addFriendsVC = segue.destinationViewController;
        
        // sender contains habit tapped
        addFriendsVC.tribe = sender;
        
    } else if ([segue.identifier isEqualToString:@"AddHabit"]) {
        
        
        // get tribe VC to set the tribe
        AddHabitTableViewController * addHabitVC = segue.destinationViewController;
        
        // sender contains habit tapped
        addHabitVC.tribe = sender;
        
    }
}
@end
