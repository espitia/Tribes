//
//  HabitsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "HabitsTableViewController.h"
#import "AddHabitTableViewController.h"
#import "Habit.h"

@interface HabitsTableViewController ()

@end

@implementation HabitsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set vc title
    self.navigationItem.title = @"Habits 🏋";
    
    // right button to add habit
    UIBarButtonItem * addHabitButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addHabit)];
    [self.navigationItem setRightBarButtonItem:addHabitButton];
}

-(void)addHabit {
    [self performSegueWithIdentifier:@"AddHabit" sender:_tribe];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribe.habits.count;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HabitCell" forIndexPath:indexPath];
    
    Habit * habit = [_tribe.habits objectAtIndex:indexPath.row];
    cell.textLabel.text = habit[@"name"];
    
    
    return cell;
}


#pragma mark - Segue navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"AddHabit"]) {
        
        // get tribe VC to set the tribe
        AddHabitTableViewController * addHabitVC = segue.destinationViewController;
        
        // sender contains habit tapped
        addHabitVC.tribe = sender;
        
    }
}

@end
