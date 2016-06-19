//
//  TribeDetailTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribeDetailTableViewController.h"
#import "TribesTableViewController.h"
#import "User.h"
#import "HabitSettingsTableViewController.h"
#import "SCLAlertView.h"
#import "HYBubbleButton.h"
#import <Crashlytics/Crashlytics.h>
#import <Leanplum/Leanplum.h>

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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


-(PFQuery *)queryForTable {
    PFQuery * query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"habit" equalTo:_habit];
    [query includeKey:@"createdBy"];
    if (weeklyCompletions) {
        [query orderByDescending:@"weeklyCompletions"];
    } else {
        [query orderByDescending:@"completions"];
    }
    
    
    PFRelation * relation = [self.tribe relationForKey:@"members"];
    PFQuery * membersQuery = [relation query];
    [query whereKey:@"createdBy" matchesQuery:membersQuery];
    
    return query;
}

- (void)objectsDidLoad:(nullable NSError *)error {
    [super objectsDidLoad:error];
}

-(PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    PFTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    Activity * activity = [self.objects objectAtIndex:indexPath.row];
    User * user = [activity objectForKey:@"createdBy"];
    
    NSString * username = user.username;
    cell.textLabel.text = username;
    
    if (weeklyCompletions) {
        cell.detailTextLabel.text = [self formatCompletionsStringForActivity:activity andCompletions:activity.weekCompletions];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", activity[@"completions"]];
    }
    
    return cell;
}

#pragma mark - Touches on cell

- (void)tableTapped:(UITapGestureRecognizer *)tap
{
    CGPoint location = [tap locationInView:self.tableView];
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath) {
        
        // init necessary variables
        User * member = _habit.membersAndActivities[indexPath.row][@"member"];
        User * currentUser = [User currentUser];
        Activity * activity = _habit.membersAndActivities[indexPath.row][@"activity"];
        
        // init alert vars
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        NSString * message;
        
        // if selected own member cell -> show settings
        if (member == currentUser) {
            
            // log event
            [Answers logCustomEventWithName:@"Tapped to see habit settings" customAttributes:@{}];
            [Leanplum track:@"Tapped to see habit setting"];

            
            [self performSegueWithIdentifier:@"showSettings" sender:activity];
            
        } else if (activity.hibernation) {
            
            // let user know
            message = [NSString stringWithFormat:@"%@ is hibernating!\n Let it be 😴", member[@"username"]];
            [alert showInfo:@"🐻" subTitle:message closeButtonTitle:@"OK" duration:0.0];
            
        } else if (activity.watcher) {
            
            // let user know
            message = [NSString stringWithFormat:@"%@ is a watcher!\n Only here to motivate those who are participating in this habit 😎", member[@"username"]];
            [alert showInfo:@"👀" subTitle:message closeButtonTitle:@"OK" duration:0.0];
            
        }
        
        else if ([[member activityForHabit:_habit] completedForDay]) {
            
            // send applause
            [self showBubbleEffectAndSendApplausePushWithLocation:location toUser:member];

            
        } else {
            
            // send motivation
            [self showBubbleEffectAndSendPushWithLocation:location toUser:member];
        }
    }

}

-(void)showBubbleEffectAndSendApplausePushWithLocation:(CGPoint)location toUser:(User *)member {
    
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
        UIImage * lion = [self imageFromText:@"👏"];
        bubbleGenerator.images = @[lion];
 
        // log event
        [Answers logCustomEventWithName:@"Sent applause" customAttributes:@{}];
        [Leanplum track:@"Sent applause"];
        
        NSString * message = [NSString stringWithFormat:@"%@: 👏 (%@)", [User currentUser][@"username"], self.habit[@"name"]];
        
        NSString * category = @"THANK_YOU_FOR_APPLAUSE_REPLY";
        [[User currentUser] sendPushFromMemberToMember:member withMessage:message habitName:self.habit[@"name"] andCategory:category];
  
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
                
                // log event
                [Answers logCustomEventWithName:@"Sent motivation" customAttributes:@{@"success":@true}];
                [Leanplum track:@"Sent motivation"];
                
            } else {
                
                // log event
                [Answers logCustomEventWithName:@"Sent motivation" customAttributes:@{@"success":@false}];
                
                // show error alert
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
    
    if (activity.watcher)
        return @"👀";
    
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
        HabitSettingsTableViewController * vc = (HabitSettingsTableViewController *)segue.destinationViewController;
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
            [self loadObjects];
            break;
        case 1:
            weeklyCompletions = false;
            [self loadObjects];
            break;
            
        default:
            break;
    }
}





@end
