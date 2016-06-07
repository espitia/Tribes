//
//  TribesTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribesTableViewController.h"
#import "Parse.h"
#import "TribeDetailTableViewController.h"
#import "TribeMenuTableViewController.h"
#import "MembersTableViewController.h"
#import "AddFriendsTableViewController.h"
#import "Tribe.h"
#import "Habit.h"
#import "MCSwipeTableViewCell.h"
#import <Crashlytics/Crashlytics.h>
#import "User.h"
#import "Activity.h"
#import "KRConfettiView.h"
#import "YLProgressBar.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SCLAlertView.h"
#import "WeeklyReportTableViewController.h"
#import "PremiumViewController.h"
#import "IAPHelper.h"
#import "AddHabitTableViewController.h"
#import <Leanplum/Leanplum.h>
#import "AppDelegate.h"


@import AVFoundation;
@import AVKit;
@interface TribesTableViewController () <MCSwipeTableViewCellDelegate> {
    User * currentUser;
    UIRefreshControl * refreshControl;
    YLProgressBar * progressBar;
    KRConfettiView * confettiView;
    BOOL bannerIsVisible;
}

@end

@implementation TribesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set currentUser
    currentUser = [User currentUser];
 
    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
    
        self.navigationItem.title = @"Loading Tribes..";
        [self setUp];
        [self UISetUp];
        
        [currentUser loadTribesWithBlock:^(bool success) {
            
            if (success) {
                self.navigationItem.title = @"Tribes";
                currentUser.loadedInitialTribes = true;
                [self.tableView reloadData];
                [self updateProgressBar];
                [currentUser checkForPendingMemberswithBlock:^(BOOL newPendingMembers) {
                    if (newPendingMembers)
                        [self.tableView reloadData];
                }];
                
                // if user is waiting to be accepted, check for new tribes
                // else check for new data (members, habits, etc)
                if (currentUser.onHoldTribes.count > 0) {
                    [self checkForTribesConfirmationTimer];
                } else {
                    [self checkForNewData];
                }
                
            } else {
                SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
                [alert addButton:@"MAGIC BUTTON" actionBlock:^{
                    [self refreshTable];
                }];
                [alert showError:@"Oh oh.. 😬" subTitle:@"There was an error while loading your Tribes. This shouldn't happen. Ever! So now, let's try to fix it by tapping the magic button below 👇" closeButtonTitle:nil duration:0.0];
            }
            
        }];
    }
    

}

-(void)viewDidAppear:(BOOL)animated {
    
    // security check
    if (!currentUser)
        currentUser = [User currentUser];
    
    // set up UI elements
    [self.tableView reloadData];
    
    // check to show walkthrough video
    if ([self shouldPlayWalkthroughVideo]) {
        // show alert to user that we are going to show a tutorial video
        [self showAlertForWalkthroughVideo];
    } else if ([self shouldAskForNotificationsPermission]) {
        [self askForNotificationsPermission];
    }
    
    if (currentUser.onHoldTribes.count > 0)
        [self checkForTribesConfirmationTimer];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // if user has no tribe - add call to action to create/join one
    if (currentUser.tribes.count == 0 && currentUser.onHoldTribes.count == 0)
        return 1;
    
    return currentUser.tribes.count + currentUser.onHoldTribes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section < currentUser.onHoldTribes.count)
        return 1;
    
    if (!currentUser.tribes || !currentUser.loadedInitialTribes)
        return 0;
    

    
    Tribe * tribe = [currentUser.tribes objectAtIndex:section - currentUser.onHoldTribes.count];

    // if tribe has no habits - add call to action to create a habit
    if ([tribe[@"habits"] count] == 0)
        return 1;
    
    // if tirbe has no members - add call to action to add a friend
    if (tribe.tribeMembers.count == 1)
        return [tribe[@"habits"] count] + 1;

    if (currentUser.weeklyReportActive) {
        return [tribe[@"habits"] count] + 1;
    } else {
        return [tribe[@"habits"] count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (!currentUser.loadedInitialTribes)
        return nil;
    
    // create view for section header (tribe)
    UIView * headerView = [[UIView alloc] init];
    [headerView setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100)];
    [headerView setBackgroundColor:[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0]];
    
    // add tap recognizer to be able to show user members/habits section
    if (!headerView.gestureRecognizers) {
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sectionHeaderTap:)];
        [headerView addGestureRecognizer:tap];
    }
    
    // set title for tribe
    UILabel * titleLabel = [[UILabel alloc] init];
    [titleLabel setFrame:CGRectMake(16, 34, self.tableView.frame.size.width - 12, 38)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:30]];
    
    // if user has no tribe - add call to action to create/join one
    if (currentUser.tribes.count == 0 && currentUser.onHoldTribes.count == 0) {
        [titleLabel setText:@"👆 Tap to join a Tribe"];
        [headerView addSubview:titleLabel];
        return headerView;
    }
    
    // if user is on hold for a tribe, show "waiting for" and move tribe index
    else if (section < currentUser.onHoldTribes.count) {
        [self configureViewForHeaderView:headerView];
        return headerView;
    }
    
    // tribe from data model
    Tribe * tribe = [currentUser.tribes objectAtIndex:section - currentUser.onHoldTribes.count];
    [titleLabel setText:tribe.name];
    
    // create label for 🦁 or 🐑
    UILabel * lionOrSheepTribe = [[UILabel alloc] init];
    [lionOrSheepTribe setFrame:CGRectMake(337, 35, 40, 40)];
    
    // check if al members completed all habits to set
    lionOrSheepTribe.text = ([tribe allHabitsAreCompleted]) ? @"🦁" : @"🐑" ;
    
    // add labels to header view
    [headerView addSubview:lionOrSheepTribe];
    [headerView addSubview:titleLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TribeCell";
    
    MCSwipeTableViewCell * cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        // iOS 7 separator
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    if (indexPath.section < currentUser.onHoldTribes.count) {
        cell.textLabel.text = @"Tell your Tribe admin to accept you!";
        return cell;
    }
    
    // if user created a tribe but tribe has no habits - call to action to add one
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.section - currentUser.onHoldTribes.count];
    
    // if tribe has no habits - add call to action to create a habit
    if ([tribe[@"habits"] count] == 0) {
        cell.textLabel.text = @"👆 Tap to add a habit";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    // if tribe has no habits - add call to action to add a friend
    if (tribe.tribeMembers.count == 1 && tribe.onHoldMembers.count == 0 && indexPath.row == 0) {
        cell.textLabel.text = @"👆 Tap to add a friend";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    if (tribe.onHoldMembers.count > 0 && indexPath.row == 0 && [currentUser isAdmin:tribe]) {
        cell.textLabel.text = @"👆 You've got pending members!";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    // regular cell when showing call to action to add friend
    else if ((tribe.tribeMembers.count == 1 || tribe.onHoldMembers.count > 0) && indexPath.row != 0) {
        NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        [self configureCell:cell forRowAtIndexPath:newIndexPath];
        return cell;
    }
    
    // enable weekly reports on monday and configure indexpath to correctly user data source
    else if (currentUser.weeklyReportActive && indexPath.row == 0) {
        [self configureWeeklyReportCell:cell forRowAtIndexPath:indexPath];
        return cell;
    }
    // regular cells for when weekly report is on (modify indexpath)
    else if (currentUser.weeklyReportActive && indexPath.row != 0) {
        NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        [self configureCell:cell forRowAtIndexPath:newIndexPath];
        return cell;
    }
    // regular day
    else {
        [self configureCell:cell forRowAtIndexPath:indexPath];
    }
    return cell;
}

#pragma mark - Configure Cell
- (void)configureWeeklyReportCell:(MCSwipeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = @"Weekly report 📈";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}
- (void)configureCell:(MCSwipeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    // makes sure tribe objects have been loaded
    if (!currentUser.loadedInitialTribes)
        return;
    
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.section - currentUser.onHoldTribes.count];
    Habit * habit = [tribe[@"habits"] objectAtIndex:indexPath.row];

    
    // cell modifications that go for both complete/uncomplete tribes
    [self configureCellForAllTribes:cell withHabit:habit];
    
    // cell modifications depending on watcher|hibernation/completion/uncompleted
    if ([currentUser activityForHabit:habit].watcher || [currentUser activityForHabit:habit].hibernation) {
        [self configureCellForSetting:cell withHabit:habit]; // for watcher/hibernation settings
    } else if ([habit completedForDay]) {
        [self configureCellForCompletedTribeHabit:cell withTribe:tribe andHabit:habit];
    } else if (![habit completedForDay]) {
        [self configureCellForUncompleteTribeHabit:cell withTribe:tribe andHabit:habit atIndexPath:indexPath];
    }
    
}

- (void)configureCellForAllTribes:(MCSwipeTableViewCell *)cell withHabit:(Habit *)habit  {
    
    // set name of tribe
    [cell.textLabel setText:habit[@"name"]];
    
    // set detail text depending on whether all tribe members completed their activity
    NSString * detailText = ([habit allMembersCompletedActivity]) ? @"🦁" : @"🐑" ;
    [cell.detailTextLabel setText:detailText];


}
- (void)configureCellForCompletedTribeHabit:(MCSwipeTableViewCell *)cell withTribe:(Tribe *)tribe andHabit:(Habit *)habit  {
   
    // set detail text depending on whether all tribe members completed their activity
    NSString * check = @"✅";
    NSString * detailText = [check stringByAppendingString:cell.detailTextLabel.text];
    [cell.detailTextLabel setText:detailText];
    
    // cross out habit if user compelted
    NSDictionary* attributes = @{NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]};
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:habit[@"name"] attributes:attributes];
    
    cell.textLabel.attributedText = attributedString;
}

- (void)configureCellForUncompleteTribeHabit:(MCSwipeTableViewCell *)cell withTribe:(Tribe *)tribe andHabit:(Habit *)habit atIndexPath:(NSIndexPath *)indexPath {

    // set detail text depending on whether all tribe members completed their activity
    NSString * notCompleteX = @"❌";
    NSString * detailText = [notCompleteX stringByAppendingString:cell.detailTextLabel.text];
    [cell.detailTextLabel setText:detailText];
    
    UIView *checkView = [self viewWithImageName:@"check"];
    UIColor *greenColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {

        // log event
        [Answers logCustomEventWithName:@"Complete habit" customAttributes:@{}];
        [Leanplum track:@"Complete habit"];

        [currentUser completeActivityForHabit:habit inTribe:tribe];
        [self makeItRainConfetti];
        [self updateProgressBar];
        [self playSound:@"completion-sound" :@".mp3"];
        // modify indexpath to accomadte for weekly report cell
        if (currentUser.weeklyReportActive) {
            NSIndexPath * weeklyReportIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
            [self.tableView reloadRowsAtIndexPaths:@[weeklyReportIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

    }];
}

/**
 * Modify cell depending on habit setting (hibernation 🐻 or watcher 👀)
 */
- (void)configureCellForSetting:(MCSwipeTableViewCell *)cell withHabit:(Habit *)habit  {
    
    Activity * activity = [currentUser activityForHabit:habit];
    
    NSString * stringAddition;
    if (activity.hibernation) {
        stringAddition = @"🐻";
    } else if (activity.watcher) {
        stringAddition = @"👀";
    }
    NSString * detailText = [stringAddition stringByAppendingString:cell.detailTextLabel.text];
    [cell.detailTextLabel setText:detailText];
}

-(void)configureViewForHeaderView:(UIView *)headerView {
    // set title for tribe
    UILabel * titleLabel = [[UILabel alloc] init];
    [titleLabel setFrame:CGRectMake(16, 34, self.tableView.frame.size.width - 12, 38)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:30]];
    
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:20]];
    [titleLabel setText:@"Waiting on Tribe confirmation.."];
    [headerView addSubview:titleLabel];
    
    UIActivityIndicatorView * indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator setFrame:CGRectMake(337, 35, 40, 40)];
    [headerView addSubview:indicator];
    [indicator startAnimating];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section < currentUser.onHoldTribes.count)
        return;
    
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.section - currentUser.onHoldTribes.count];
    
    // if user has no habits in tribe, send them to add habit
    if ([tribe[@"habits"] count] == 0) {
        
        // log event
        [Answers logCustomEventWithName:@"Tapped to create first habit" customAttributes:@{}];
        [Leanplum track:@"Add first habit"];
        
        [self performSegueWithIdentifier:@"AddFirstHabit" sender:tribe];
    }
    
    // if user has no tribe members , send them add friends
    else if (tribe.tribeMembers.count == 1 && tribe.onHoldMembers.count == 0 && indexPath.row == 0) {
        
        [self performSegueWithIdentifier:@"addFriendToTribe" sender:tribe];
        [Leanplum track:@"Add first friend"];
    }
    
    // pending members action
    else if (tribe.onHoldMembers.count > 0 && indexPath.row == 0 && [currentUser isAdmin:tribe]) {
        [self performSegueWithIdentifier:@"showMembersTable" sender:tribe];
    }
    // if user has no tribe members but has habits, send them to corresponding habits
    else if ((tribe.tribeMembers.count == 1 || tribe.onHoldMembers.count > 0) && indexPath.row != 0) {
        
        // log event
        [Answers logCustomEventWithName:@"Tapped on habit" customAttributes:@{}];
        [Leanplum track:@"Tapped on habit"];
        
        NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        Habit * habit = [tribe[@"habits"] objectAtIndex:newIndexPath.row];
        [self performSegueWithIdentifier:@"showTribeHabit" sender:habit];
    }
    // enable weekly reports on Monday and configure indexpath to correctly user data source
    else if (currentUser.weeklyReportActive && indexPath.row == 0) {
        
        IAPHelper * helper = [[IAPHelper alloc] init];
        if ([helper userIsPremium]) {
            
            [self performSegueWithIdentifier:@"showWeeklyReport" sender:tribe];
        
        } else {
            
            // show alert to upgrade to premium
            SCLAlertView * premiumFeatureAlert = [[SCLAlertView alloc] initWithNewWindow];
            [premiumFeatureAlert addButton:@"MORE INFO" actionBlock:^{
                // show premium vc
                PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumWeeklyReport];
                [self presentViewController:premiumVC animated:true completion:nil];
            }];
            [premiumFeatureAlert showSuccess:@"Premium Feature" subTitle:@"You've discovered a premium feature! Upgrading to Tribes Premium will unlock it." closeButtonTitle:@"MAYBE LATER" duration:0.0];
        }

    }
    // REPORT DAYS (MONDAY) BUT NOT TAPPING REPORT (tapping a habit instead)
    else if (currentUser.weeklyReportActive && indexPath.row != 0) {
        
        NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        Habit * habit = [tribe[@"habits"] objectAtIndex:newIndexPath.row];
        [self performSegueWithIdentifier:@"showTribeHabit" sender:habit];
        
    }
    // REGULAR DAYS
    else {

        // log event
        [Answers logCustomEventWithName:@"Tapped on habit" customAttributes:@{}];
        [Leanplum track:@"Tapped on habit"];

        
        Habit * habit = [tribe[@"habits"] objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"showTribeHabit" sender:habit];
    }
}

-(void)sectionHeaderTap:(UITapGestureRecognizer *)tap {
    
    // if user has no tribe - add call to action to create/join one
    if (currentUser.tribes.count == 0) {
        
        // log event
        [Answers logCustomEventWithName:@"Tapped to add first Tribe" customAttributes:@{}];
        [Leanplum track:@"Add first Tribe"];

        [self performSegueWithIdentifier:@"ShowTribeManager" sender:nil];
        
        return;
    }
    
    // get tribe that was tapped on to send to tribe menu vc control
    for (UILabel * label in tap.view.subviews) {
        for (Tribe * tribe in currentUser.tribes) {
            if ([label.text isEqualToString:tribe.name]) {
                [self performSegueWithIdentifier:@"TribeMenu" sender:tribe];
            } else if ([label.text isEqualToString:@"Waiting on Tribe confirmation.."]) {
                return;
            }
        }
    }
    
}

#pragma mark - User login/signup

-(void)signUp {

    UINavigationController * SignUpLoginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignUpLoginViewController"];
    [self.navigationController presentViewController:SignUpLoginViewController animated:YES completion:nil];
}

#pragma mark - Segue handling

-(IBAction)unwindFromAddTribe:(UIStoryboardSegue *)segue {
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"showTribeHabit"]) {
        
        // get tribe VC to set the tribe
        TribeDetailTableViewController * tribeDetailVC = segue.destinationViewController;
        
        // sender contains habit tapped
        tribeDetailVC.habit = sender;
    } else if ([segue.identifier isEqualToString:@"TribeMenu"]) {
        
        // get tribe menu vc to set tribe
        TribeMenuTableViewController * tribeMenuVC = segue.destinationViewController;
        // sender contrains tribe tapped
        tribeMenuVC.tribe = sender;
        
    } else if ([segue.identifier isEqualToString:@"showWeeklyReport"]) {
        // get tribe menu vc to set tribe
        WeeklyReportTableViewController * weeklyReportVC = segue.destinationViewController;
        // sender contrains tribe tapped
        weeklyReportVC.tribe = sender;
    } else if ([segue.identifier isEqualToString:@"AddFirstHabit"]) {
        // if tribe has no habits, send to add first habit
        AddHabitTableViewController * vc = (AddHabitTableViewController *)segue.destinationViewController;
        vc.tribe = sender;
    } else if ([segue.identifier isEqualToString:@"addFriendToTribe"]) {
        // send to add friend to tribe when tribe has no tribe members other than user,
        AddFriendsTableViewController * vc = (AddFriendsTableViewController *)segue.destinationViewController;
        vc.tribe = sender;
    } else if ([segue.identifier isEqualToString:@"showMembersTable"]) {
        // send to add friend to tribe when tribe has no tribe members other than user,
        MembersTableViewController * vc = (MembersTableViewController *)segue.destinationViewController;
        vc.tribe = sender;
    }
}

#pragma mark - Helper methods

/**
 * - registers table view cell
 * - adds pull to refresh control
 * - adds notification to handle entered foreground
 */
-(void)setUp {
    // register table view cell
    [self.tableView registerClass:[MCSwipeTableViewCell class] forCellReuseIdentifier:@"TribeCell"];
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleEnteredForeground) name:UIApplicationDidBecomeActiveNotification object: nil];
    
}

-(void)UISetUp {
    
    [self addPullToRefresh];
    
    // set table section height (tribe height)
    self.tableView.sectionHeaderHeight = 100;
    
    // add and update progress bar
    [self addProgressBar];
}

-(void)handleEnteredForeground {
    
    // check for pending members if current user is admin of a tribe
    [currentUser checkForPendingMemberswithBlock:^(BOOL newPendingMembers) {
        if (newPendingMembers)
            [self.tableView reloadData];
    }];
    
    
    //  update activities when entering foreground
    [currentUser updateMemberActivitiesForAllTribesWithBlock:^(bool success) {
        if (success) {
            [self.tableView reloadData];
            [self updateProgressBar];
            if (currentUser.onHoldTribes.count == 0)
                [self checkForNewData];
        } else {
            NSLog(@"failed to update activities");
        }
    }]; 
}
-(void)checkForTribesConfirmationTimer {
    //NSTimer calling Method B, as long the audio file is playing, every 5 seconds.
    [NSTimer scheduledTimerWithTimeInterval:5.0f
                                     target:self selector:@selector(checkForTribesConfirmation:) userInfo:nil repeats:YES];
}
- (void)checkForTribesConfirmation:(NSTimer *)timer{
    
    [currentUser checkForNewDataWithBlock:^(bool newData) {
        
        // show alert to download new data
        if (newData) {
            
            [timer invalidate];
            
            SCLAlertView * newNewAlert = [[SCLAlertView alloc] initWithNewWindow];
            [newNewAlert addButton:@"OK" actionBlock:^{
                
                [self refreshTable];
                
            }];
            [newNewAlert showSuccess:@"Congratulations 🎉" subTitle:@"You've been accepted to a new Tribe. Make your Tribe proud ✊" closeButtonTitle:nil duration:0.0];
        } else {
            NSLog(@"no new data was found to update tribes/habits/members.");
        }
    }];
    
}

-(void)checkForNewData {
    [currentUser checkForNewDataWithBlock:^(bool newData) {
        
        // show alert to download new data
        if (newData) {
            
            SCLAlertView * newNewAlert = [[SCLAlertView alloc] initWithNewWindow];
            [newNewAlert addButton:@"OK" actionBlock:^{
                
                [self refreshTable];
                
            }];
            [newNewAlert showInfo:@"Data fairy ✨" subTitle:@"We are being told there is new stuff to be downloaded. That might be a Tribe, a new member or new habits. Or who knows, new pixie dust? Tap below to download!" closeButtonTitle:nil duration:0.0];
        } else {
            NSLog(@"no new data was found to update tribes/habits/members.");
        }
    }];
    
}
// helper method for setting images under swipeable cells
- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // add offset to progress bar frame so it doesn't move
    CGRect frame = progressBar.frame;
    frame.origin.y = scrollView.contentOffset.y + 64;
    [progressBar setFrame:frame];
    [self.view bringSubviewToFront:progressBar];
}

-(void)setAllActivitiesCompletedSignifier {
    self.navigationItem.title = @"🔥🦁 Tribes 🦁🔥";
}
-(void)removeAllActivitiesCompletedSignifier {
    self.navigationItem.title = @"Tribes";
}
-(BOOL)shouldPlayWalkthroughVideo {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    return (currentUser.tribes.count > 0 && currentUser.activities.count > 0 && [userDefaults objectForKey:@"playedWalkthroughVideo"] == NULL) &&
        ([currentUser signedUpToday]);
}
-(BOOL)shouldAskForNotificationsPermission {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    return (currentUser.tribes.count > 0 && currentUser.activities.count > 0 &&
            [currentUser hasTribesWithMembers] &&
            [[userDefaults objectForKey:@"playedWalkthroughVideo"]  isEqual: @true] &&
            ([userDefaults objectForKey:@"askedForNotificationsPermission"]  == NULL) &&
            (![currentUser pushNotificationsEnabled]));
}
-(void)showAlertForWalkthroughVideo {
    // show alert with explanation of why the video
    SCLAlertView * walkthroughVideoAlert = [[SCLAlertView alloc] initWithNewWindow];
    [walkthroughVideoAlert addButton:@"OK" actionBlock:^{
        
        [self playWalkthroughVideo];
        [Answers logCustomEventWithName:@"Played Video Tutorial" customAttributes:@{@"placement":@"initial helper alert"}];
        [Leanplum track:@"Play walkthrough video"];
        
    }];
    [walkthroughVideoAlert showSuccess:@"Helper Video 🎥" subTitle:@"Congrats on setting up your Tribe 🎉 Here's a short video to help you get the most out of it!" closeButtonTitle:nil duration:0.0];
}
-(void)playWalkthroughVideo {
    // grab a local URL to our video
    NSURL *videoURL = [[NSBundle mainBundle]URLForResource:@"cropped tribes tutorial" withExtension:@"mp4"];
    
    // create an AVPlayer
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // create a player view controller
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    controller.player = player;
    
    // present view controller
    [self presentViewController:controller animated:true completion:nil];
    [player play];
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@true forKey:@"playedWalkthroughVideo"];
    [userDefaults synchronize];
    

}

-(void)askForNotificationsPermission {
    // setup alert
    SCLAlertView * notificationAlert = [[SCLAlertView alloc] initWithNewWindow];
    [notificationAlert addButton:@"YES PLEASE" actionBlock:^{

        //ask for notification permission
        AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
        [delegate setUpNotifications:[UIApplication sharedApplication]];
    
    }];
    
    // show alert
    [notificationAlert showInfo:@"Notifications 📲" subTitle:@"Would you like to send and receive motivation from friends?" closeButtonTitle:nil duration:0.0];
    
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@true forKey:@"askedForNotificationsPermission"];
    [userDefaults synchronize];
}

#pragma mark - Method to play sound

- (void)playSound:(NSString *)fileName :(NSString *)ext {
    SystemSoundID audioEffect;
    NSString *path = [[NSBundle mainBundle] pathForResource : fileName ofType :ext];
    if ([[NSFileManager defaultManager] fileExistsAtPath : path]) {
        NSURL *pathURL = [NSURL fileURLWithPath: path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &audioEffect);
        AudioServicesPlaySystemSound(audioEffect);
    }
}


#pragma mark - Refresh data

-(void)addPullToRefresh {
    // add refresh control
    if (!refreshControl) {
        refreshControl = [[UIRefreshControl alloc]init];
        [self.tableView addSubview:refreshControl];
        [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    }
    
}
-(void)refreshTable {
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert showWaiting:@"Fetching Tribes" subTitle:@"🏃💨" closeButtonTitle:nil duration:0.0];
    [currentUser updateTribesWithBlock:^(bool success) {
        if (success) {
            
            [currentUser loadTribesWithBlock:^(bool success) {
                currentUser.loadedInitialTribes = true;
                [alert hideView];
                [refreshControl endRefreshing];
                
                [self.tableView reloadData];
                [self updateProgressBar];

            }];

        } else {
            [refreshControl endRefreshing];
            [alert hideView];

            SCLAlertView * error = [[SCLAlertView alloc] initWithNewWindow];
            [error showError:@"🙄" subTitle:@"There was an error fetching your Tribes. We agree, errors are annoying. Please make sure your internet connection is working and swipe down to reload your Tribes!" closeButtonTitle:@"OK" duration:0.0];
            [refreshControl endRefreshing];
        }
    }];

}

#pragma mark - Progress Bar

-(void)addProgressBar {
    
    // set up progr
    if (!progressBar) {
        progressBar = [[YLProgressBar alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,10)];
        progressBar.type                = YLProgressBarTypeFlat;
        progressBar.trackTintColor      = [UIColor clearColor];
        progressBar.progressTintColor   = [UIColor colorWithRed:105.0/255.0 green:203.0/255.0 blue:149.0/255.0 alpha:1.0];
        progressBar.trackTintColor      = [UIColor lightGrayColor];
        progressBar.indicatorTextLabel.text  = @"";
        progressBar.hideGloss           = YES;
        progressBar.hideStripes         = YES;
        progressBar.indicatorTextDisplayMode = YLProgressBarIndicatorTextDisplayModeTrack;
        [progressBar setProgress:0.0];
        [self.tableView addSubview:progressBar];
    }

    
    [self updateProgressBar];
    
}
-(void)updateProgressBar {
    
    // makes sure tribe objects have been loaded
    if (!currentUser.loadedInitialTribes || !currentUser.tribes)
        return;
    
    float numberOfHabitsOnWatcher = 0;
    for (Activity * activity in currentUser.activities) {
        if (activity.watcher) {
            numberOfHabitsOnWatcher++;
        }
    }
    float numberOfHabits = (float)currentUser.activities.count - numberOfHabitsOnWatcher;
    float completionProgress = 100.0/numberOfHabits;
    float completions = 0;
    for (Activity * activity in currentUser.activities) {
        if ([activity completedForDay]) {
            completions++;
        }
    }

    float totalProgress = (completionProgress * completions) * .01 ;
    
    // // add signifier of a true 🦁 when all activities are complete
    if (totalProgress == 1.0) {
        [self setAllActivitiesCompletedSignifier];
    } else {
        [self removeAllActivitiesCompletedSignifier];
    }
    // set progress 
    [progressBar setProgress:totalProgress animated:YES];
}

#pragma mark - Confetti

-(void)makeItRainConfetti {
    
    // if confetti has not been initialized
    if (!confettiView) {
        
        // Create confetti view
        confettiView = [[KRConfettiView alloc] initWithFrame:self.view.frame];
        
        // Set colors (default colors are red, green and blue)
        confettiView.colours = @[[UIColor colorWithRed:0.95 green:0.40 blue:0.27 alpha:1.0],
                                 [UIColor colorWithRed:1.00 green:0.78 blue:0.36 alpha:1.0],
                                 [UIColor colorWithRed:0.48 green:0.78 blue:0.64 alpha:1.0],
                                 [UIColor colorWithRed:0.30 green:0.76 blue:0.85 alpha:1.0],
                                 [UIColor colorWithRed:0.58 green:0.39 blue:0.55 alpha:1.0]];
        
        //Set intensity (from 0 - 1, default intensity is 0.5)
        confettiView.intensity = 0.7;
        
        //set type
        confettiView.type = Diamond;
        
        //For custom image
        //confettiView.customImage = [UIImage imageNamed:@"diamond"];
        //confettiView.type = Custom;
    }

    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self
                                   selector: @selector(stopConfetti)
                                   userInfo:nil
                                    repeats:NO];
    //add subview
    [self.view addSubview:confettiView];
    
    // make it rain confetti!
    [confettiView startConfetti];
}
-(void)stopConfetti {
    [confettiView stopConfetti];
}




@end









