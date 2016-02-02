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

@interface TribeDetailTableViewController () {
    NSMutableArray * membersAndActivities;
    BOOL weeklyCompletions;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to Add friends
    [self addRightButton];
    
    // add segment control for weekly or all-time completions
    [self addSegmentControl];
    
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
   
    // dictionary with member (PFUser)and acitivty key (Activity object)
    PFUser * member = _tribe.membersAndActivities[indexPath.row][@"member"];
    Activity * activity = _tribe.membersAndActivities[indexPath.row][@"activity"];

    cell.textLabel.text = member[@"username"];
    
    NSString * completionsString;
    int completions;
    
    if (weeklyCompletions) {
        [_tribe sortMembersAndActivitiesByWeeklyActivityCompletions];
        completions = activity.weekCompletions;
    } else {
        [_tribe sortMembersAndActivitiesByTotalActivityCompletions];
        completions = [activity[@"completions"] intValue];
    }
    
    // format detail string depending if user completed activity or not
    if ([activity completedForDay]) {
        completionsString = [NSString stringWithFormat:@"🦁%d🔥", completions];
    } else {
        completionsString = [NSString stringWithFormat:@"🐑%d🔥", completions];
    }
    
    cell.detailTextLabel.text = completionsString;
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![_tribe membersAndActivitesAreLoaded]) {
        // alert user that member and activites are not loaded
        return;
    }

    User * member = _tribe.membersAndActivities[indexPath.row][@"member"];
    User * currentUser = [User currentUser];

    // send push to tapped on member
    [currentUser sendMotivationToMember:member inTribe:_tribe withBlock:^(BOOL success) {
        if (success) {
            [self showAlert];
        }
    }];
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
    }
}


-(void)showAlert {
    // weak self to not have any issues to present alert view
    __unsafe_unretained typeof(self) weakSelf = self;
    
    // alert controller
    UIAlertController * __block alert;
    UIAlertAction * __block defaultAction;
    
    // message to go in alert view
    NSString * __block alertTitle = @"";
    NSString * __block alertMessage = @"";
    

    alertTitle = @"✅✅✅";
    alertMessage = @"Successfully sent motivation.\n Liooon! 🦁";
    
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
@end
