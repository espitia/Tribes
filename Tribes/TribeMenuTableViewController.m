//
//  TribeMenuTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeMenuTableViewController.h"
#import "User.h"
#import "Habit.h"

@interface TribeMenuTableViewController () {
    BOOL showMembers;
}

@end

@implementation TribeMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set initial selection of what to show
    showMembers = true;
    
    // add segemnet control to switch between membs and habits
    [self addSegmentControl];
    
    // set title of vc to tribe name
    self.navigationItem.title = _tribe[@"name"];
    
    // right button to add member/habit
    UIBarButtonItem * addMemberOrHabitButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addMemberOrHabit)];
    [self.navigationItem setRightBarButtonItem:addMemberOrHabitButton];

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}


#pragma mark - Segement control

-(void)addSegmentControl {
    
    // default stats to show -> weekly
    showMembers = true;
    
    // create and add segement control
    UISegmentedControl * segmentedControl = [[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Members", @"Habits", nil]];
    segmentedControl.layer.borderColor = [UIColor whiteColor].CGColor;
    segmentedControl.layer.borderWidth = 1.0;
    [segmentedControl setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
    [segmentedControl addTarget:self action:@selector(segmentedControlHasChangedValue:) forControlEvents:UIControlEventValueChanged];
    self.tableView.tableHeaderView = segmentedControl;
    
    // set default stats to show
    [segmentedControl setSelectedSegmentIndex:0];
}

-(void)segmentedControlHasChangedValue:(id)sender {
    
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    
    switch (selectedSegment) {
        case 0:
            showMembers = true;
            [self.tableView reloadData];
            break;
        case 1:
            showMembers = false;
            [self.tableView reloadData];
            
            break;
            
        default:
            break;
    }
}

#pragma mark - Adding Members and Habits

-(void)addMemberOrHabit {
    
    
    if (showMembers) {
        [self performSegueWithIdentifier:@"AddFriends" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"AddHabit" sender:nil];
    }

    
}
@end
