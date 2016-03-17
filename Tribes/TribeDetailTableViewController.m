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
#import "HYBubbleButton.h"


@interface TribeDetailTableViewController () {
    NSMutableArray * membersAndActivities;
    BOOL weeklyCompletions;
    // ** motivation pushes vars **//
    HYBubbleButton * bubbleGenerator;
    int motivationPushControl;
    BOOL firstPush;
    User * currentUserBeingSentMotivation;
}

@end

@implementation TribeDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // add segment control for weekly or all-time completions
    [self addSegmentControl];
    
    // set title
    self.navigationItem.title = _habit[@"name"];

    // tap to handle cell selection (motivation, hibernation, settings, etc)
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTapped:)];
    [self.tableView addGestureRecognizer:tap];
    
    // first push
    firstPush = true;

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _habit.members.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeMemberCell" forIndexPath:indexPath];
   
    (weeklyCompletions) ? [_habit sortMembersAndActivitiesByWeeklyActivityCompletions] : [_habit sortMembersAndActivitiesByTotalActivityCompletions];

    // dictionary with member (PFUser)and acitivty key (Activity object)
    User * member = _habit.membersAndActivities[indexPath.row][@"member"];
    Activity * activity = _habit.membersAndActivities[indexPath.row][@"activity"];
    
    NSString * titleLabel = [NSString stringWithFormat:@"%@",member[@"name"]];
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
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];


}

#pragma mark - Touches on cell

- (void)tableTapped:(UITapGestureRecognizer *)tap
{
    CGPoint location = [tap locationInView:self.tableView];
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath) {

        
//        if (![_habit membersAndActivitesAreLoaded]) {
//            // alert user that member and activites are not loaded
//            return;
//        }
        
        // init necessary variables
        User * member = _habit.membersAndActivities[indexPath.row][@"member"];
        User * currentUser = [User currentUser];
        Activity * activity = _habit.membersAndActivities[indexPath.row][@"activity"];
        
        // init alert vars
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        NSString * message;
        
        // if selected own member cell -> show settings
        if (member == currentUser) {
            
            [self performSegueWithIdentifier:@"showSettings" sender:activity];
            
        } else if (activity.hibernation) {
            
            // let user know
            message = [NSString stringWithFormat:@"%@ is hibernating!\n Let it be 😴", member[@"name"]];
            [alert showInfo:@"🐻" subTitle:message closeButtonTitle:@"OK" duration:0.0];
            
        } else if ([[member activityForHabit:_habit] completedForDay]) {
            
            // let user know
            message = [NSString stringWithFormat:@"%@ already did it!\n Let it be 🦁", member[@"name"]];
            [alert showInfo:@"🖐" subTitle:message closeButtonTitle:@"OK" duration:0.0];
            
            
        } else {
            [self showBubbleEffectAndSendPushWithLocation:location toUser:member];
        }
    }

}

-(void)showBubbleEffectAndSendPushWithLocation:(CGPoint)location toUser:(User *)member {
    
    // makes sure that if user switches user being sent motivation, we reset (1st and 7th push does send)
    if (!currentUserBeingSentMotivation || currentUserBeingSentMotivation != member) {
        currentUserBeingSentMotivation = member;
        motivationPushControl = 0;
        firstPush = true;
    }
    
    // initialize bubble generator
    bubbleGenerator = [[HYBubbleButton alloc] initWithFrame:CGRectMake(location.x, location.y, 0, 0) maxLeft:150 maxRight:150 maxHeight:300];
    bubbleGenerator.backgroundColor = [UIColor clearColor];
    bubbleGenerator.maxLeft = 300;
    bubbleGenerator.maxRight = 300;
    bubbleGenerator.maxHeight = 600;
    bubbleGenerator.duration = 8;
    [self.view addSubview:bubbleGenerator];
    
    int TAPS_TO_SEND_PUSH = 6;
    
    
    // send push if first or re-starting round
    if ((motivationPushControl == 0 && firstPush) || motivationPushControl == TAPS_TO_SEND_PUSH) {
        
        // send push with lion
        UIImage * lion = [self imageFromText:@"💣"];
        bubbleGenerator.images = @[lion];
        
        
        [[User currentUser] sendMotivationToMember:member inTribe:_habit[@"tribe"] forHabit:_habit withBlock:^(BOOL success) {
            if (success) {
                
            } else {
                SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
                [alert showError:@"❌" subTitle:@"Seems like there was a problem sending the motivation 😔 Try again!" closeButtonTitle:@"OK" duration:0.0];
            }
        }];
        
        if (motivationPushControl == TAPS_TO_SEND_PUSH) {
            motivationPushControl = 0;
            firstPush = false;
        } else {
            motivationPushControl++;
        }
        
    } else {
        // send stars
        UIImage * key = [self imageFromText:@"⚡️"];
        bubbleGenerator.images = @[key];
        motivationPushControl++;
    }

    [bubbleGenerator generateBubbleInRandom];
    
}



#pragma mark - Format completion string

-(NSString *)formatCompletionsStringForActivity:(Activity *)activity andCompletions:(int)completions {
    
    if (activity.hibernation)
        return @"🐻";
    
    NSString * completionsString = @"";
    BOOL completedForDay = ([activity completedForDay]) ? true : false;

    // add 🦁 or 🐑 to signify completed for day
    completionsString = (completedForDay) ? @"🦁" : @"🐑";
    
    // add completion number
    completionsString = [completionsString stringByAppendingString:[NSString stringWithFormat:@"%d", completions]];
    
    // add completions signifier 🕯,🔥,🚀,🏆
    completionsString = [self addStreakSignifierWithCompletionsToCompletionString:completionsString withCompletions:completions];

    return completionsString;
}

-(NSString *)addStreakSignifierWithCompletionsToCompletionString:(NSString *)completionString withCompletions:(int)completions {
    
    NSString * signifier;
    
    switch (completions) {
        case 1:
        case 2:
            signifier = @"🕯";
            break;
        case 3:
        case 4:
            signifier = @"🔥";
            break;
        case 5:
        case 6:
            signifier = @"🚀";
            break;
        case 7:
            signifier = @"🏆";
            break;
            
        default:
            signifier = @"";
            break;
    }
    
    NSString * completedString = [completionString stringByAppendingString:signifier];
    return completedString;
}

#pragma mark - Helper methods


-(UIImage *)imageFromText:(NSString *)text
{
    UIFont *font = [UIFont systemFontOfSize:20.0];
    CGSize size = [text sizeWithAttributes:
                   @{NSFontAttributeName:
                         [UIFont systemFontOfSize:20.0f]}];
    if (&UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    }
    [text drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:[NSDictionary dictionaryWithObject:font
                                                                                       forKey:NSFontAttributeName]];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier  isEqual:@"showSettings"]) {
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





@end
