//
//  TribeDetailTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeDetailTableViewController.h"
#import "AddFriendsTableViewController.h"
#import "User.h"
#import "SettingsTableViewController.h"

@interface TribeDetailTableViewController () {
    NSMutableArray * membersAndActivities;
    BOOL weeklyCompletions;
    UIRefreshControl * refreshControl;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to Add friends
    [self addRightButton];
    
    // add segment control for weekly or all-time completions
    [self addSegmentControl];
    
    // add pull to refresh control
    [self addPullToRefresh];
    
    // set title
    self.navigationItem.title = _tribe[@"name"];
}

-(void)viewDidAppear:(BOOL)animated {
    [_tribe loadMembersOfTribeWithActivitiesWithBlock:^{
        [self.tableView reloadData];
    }];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribe.membersAndActivities.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeMemberCell" forIndexPath:indexPath];
   
    (weeklyCompletions) ? [_tribe sortMembersAndActivitiesByWeeklyActivityCompletions] : [_tribe sortMembersAndActivitiesByTotalActivityCompletions];
    
    // dictionary with member (PFUser)and acitivty key (Activity object)
    User * member = _tribe.membersAndActivities[indexPath.row][@"member"];
    Activity * activity = _tribe.membersAndActivities[indexPath.row][@"activity"];

    //    NSString * titleLabel = [NSString stringWithFormat:@"%@ - lvl %d",member[@"username"],  member.lvl];
    NSString * titleLabel = [NSString stringWithFormat:@"%@",member[@"username"]];
    cell.textLabel.text = titleLabel;
    
    int completions = (weeklyCompletions) ? activity.weekCompletions : [activity[@"completions"] intValue];
    NSString * completionsString = [self formatCompletionsStringForActivity:activity andCompletions:completions];
    
    cell.detailTextLabel.text = completionsString;
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // deselect cell
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (![_tribe membersAndActivitesAreLoaded]) {
        // alert user that member and activites are not loaded
        return;
    }

    User * member = _tribe.membersAndActivities[indexPath.row][@"member"];
    User * currentUser = [User currentUser];
    
    // if member already completed activity
    if ([[member activityForTribe:_tribe] completedForDay]) {
        
        // let user know
        NSString * message = [NSString stringWithFormat:@"%@ already did it!\n Let it be 🦁", member[@"username"]];
        [self showAlertWithTitle:@"🖐🖐🖐" andMessage:message];
        
    } else {
        
        // send push to tapped on member
        [currentUser sendMotivationToMember:member inTribe:_tribe withBlock:^(BOOL success) {
            if (success) {
                [self showAlertWithTitle:@"✅✅✅" andMessage:@"Successfully sent motivation.\n Liooon! 🦁"];
            }
        }];
    }

}

#pragma mark - Format completion string

-(NSString *)formatCompletionsStringForActivity:(Activity *)activity andCompletions:(int)completions {
    
    NSString * completionsString;
    BOOL streak;
    BOOL completedForDay;
    
    completedForDay = ([activity completedForDay]) ? true : false;
    streak = ([activity onStreak]) ? true : false;
    
    // add 🦁 or 🐑 to signify completed for day
    completionsString = (completedForDay) ? @"🦁" : @"🐑";
    
    // add completion number
    completionsString = [completionsString stringByAppendingString:[NSString stringWithFormat:@"%d", completions]];
    
    // add 🔥 to signify whether user is on a streak or not
    if (streak) {
        completionsString = [completionsString stringByAppendingString:[NSString stringWithFormat:@"🔥"]];
    }
    return completionsString;
}

#pragma mark - Helper methods

-(void)addFriends {
    
    [self performSegueWithIdentifier:@"AddFriends" sender:nil];
    
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
    } else if ([segue.identifier  isEqual:@"showSettings"]) {
        SettingsTableViewController * vc = (SettingsTableViewController *)segue.destinationViewController;
        vc.activity = sender;
    }
}


-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    
    // weak self to not have any issues to present alert view
    __unsafe_unretained typeof(self) weakSelf = self;
    
    // alert controller
    UIAlertController * __block alert;
    UIAlertAction * __block defaultAction;
    
    // message to go in alert view
    NSString * __block alertTitle = title;
    NSString * __block alertMessage = message;
    
    defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               
                                           }];

    // finish alert set up
    alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                message:alertMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
    
    
    // add action (if success, pop to tribe VC)
    [alert addAction:defaultAction];
    
    // present alert
    [weakSelf presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Segement control

-(void)addSegmentControl {
    
    // default stats to show -> weekly
    weeklyCompletions = true;
    
    // create and add segement control
    UISegmentedControl * segmentedControl = [[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Week", @"All-time", nil]];
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
            weeklyCompletions = true;
            [self.tableView reloadData];
            break;
        case 1:
            weeklyCompletions = false;
            [self.tableView reloadData];

            break;
            
        default:
            break;
    }
}

#pragma mark - Refresh data

-(void)addPullToRefresh {
    // add refresh control
    refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
}
-(void)refreshTable {
    [_tribe loadMembersOfTribeWithActivitiesWithBlock:^{
        [refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}
@end
