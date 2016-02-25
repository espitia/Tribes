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
#import "SCLAlertView.h"


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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
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
    
    int completions;
    NSString * completionsString;
    
    if (weeklyCompletions) {
        completions = activity.weekCompletions;
        completionsString = [self formatCompletionsStringForActivity:activity andCompletions:completions];
    } else {
        completions = [activity[@"completions"] intValue];
        completionsString = [NSString stringWithFormat:@"%d", completions];
    }
    
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

    // init necessary variables
    User * member = _tribe.membersAndActivities[indexPath.row][@"member"];
    User * currentUser = [User currentUser];
    Activity * activity = _tribe.membersAndActivities[indexPath.row][@"activity"];

    // init alert vars
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    NSString * message;

    // init date to compare if (now) is before due time; if !dueTime -> set to nil
    NSDate * dueDateTimeOnly = (activity.dueTime) ? [self removeDayMonthAndYearFrom:activity.dueTime] : nil;
    
    // if selected own member cell -> show settings
    if (member == currentUser) {
        
        [self performSegueWithIdentifier:@"showSettings" sender:activity];
        
    } else if (activity.hibernation) {
        
        // let user know
        message = [NSString stringWithFormat:@"%@ is hibernating!\n Let it be 😴", member[@"username"]];
        [alert showInfo:@"🐻" subTitle:message closeButtonTitle:@"OK" duration:0.0];
        
    } else if ([[member activityForTribe:_tribe] completedForDay]) {
        
        // let user know
        message = [NSString stringWithFormat:@"%@ already did it!\n Let it be 🦁", member[@"username"]];
        [alert showInfo:@"🖐" subTitle:message closeButtonTitle:@"OK" duration:0.0];

    
    } else if (activity.dueTime && [[NSDate date] compare:dueDateTimeOnly] == NSOrderedAscending) {
        
        // let user know
        message = [NSString stringWithFormat:@"%@ said it will get done later!\n Give time and watch the\n grasshopper grow 🐛", member[@"username"]];
        [alert showInfo:@"🕑" subTitle:message closeButtonTitle:@"OK" duration:0.0];
        
    } else {
        // send push to tapped on member
        [currentUser sendMotivationToMember:member inTribe:_tribe withBlock:^(BOOL success) {
            if (success) {
                NSString * message = @"Successfully sent motivation 🔑\n Liooon! 🦁";
                [alert showSuccess:@"📲" subTitle:message closeButtonTitle:@"OK" duration:0.0];
            } else {
                [alert showError:@"❌" subTitle:@"Seems like there was a problem sending the motivation 😔 Try again!" closeButtonTitle:@"OK" duration:0.0];
            }
        }];
    }

}

#pragma mark - Format completion string

-(NSString *)formatCompletionsStringForActivity:(Activity *)activity andCompletions:(int)completions {
    
    if (activity.hibernation)
        return @"🐻";
    
    NSString * completionsString;
    BOOL streak;
    BOOL completedForDay;
    BOOL dueTime;
    
    completedForDay = ([activity completedForDay]) ? true : false;
    streak = ([activity onStreak]) ? true : false;
    dueTime = ([activity dueTime] ? true : false);
    
    // add 🕑
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString * stringFromDate = [formatter stringFromDate:activity.dueTime];
    NSString * dueTimeString = [NSString stringWithFormat:@"🕑%@ ", stringFromDate];
    completionsString = (dueTime) ? dueTimeString : @"";
    
    // add 🦁 or 🐑 to signify completed for day
    NSString * lionOrSheep = (completedForDay) ? @"🦁" : @"🐑";
    completionsString = [completionsString stringByAppendingString:lionOrSheep];
    
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

-(NSDate *)removeDayMonthAndYearFrom:(NSDate *)date {
    
    unsigned int flags = NSCalendarUnitHour | NSCalendarUnitMinute;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:date];
    
    NSDate * now = [NSDate date];
    NSDateComponents * compsForToday = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
    components.year = compsForToday.year;
    components.month = compsForToday.month;
    components.day = compsForToday.day;
    
    NSDate* dueDateTimeOnly = [calendar dateFromComponents:components];
    return dueDateTimeOnly;
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
