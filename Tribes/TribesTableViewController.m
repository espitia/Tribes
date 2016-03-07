//
//  TribesTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribesTableViewController.h"
#import "Parse.h"
#import "SignupViewController.h"
#import "TribeDetailTableViewController.h"
#import "Tribe.h"
#import "Habit.h"
#import "MCSwipeTableViewCell.h"
#import "User.h"
#import "Activity.h"
#import "KRConfettiView.h"
#import "YLProgressBar.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SCLAlertView.h"

@interface TribesTableViewController () <MCSwipeTableViewCellDelegate> {
    User * currentUser;
    UIRefreshControl * refreshControl;
    YLProgressBar * progressBar;
    KRConfettiView * confettiView;
}

@end

@implementation TribesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set currentUser
    currentUser = [User currentUser];
    
//    [self signUp];

    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
        
        //set up
        [self setUp];
        
        self.navigationItem.title = @"Loading Tribes..";
        
        [currentUser loadTribesWithBlock:^{
            self.navigationItem.title = @"Tribes";
            [self.tableView reloadData];
            
            // add and update progress bar
            [self addProgressBar];
        }];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    
    // security check
    if (!currentUser)
        currentUser = [User currentUser];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return currentUser.tribes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // makes sure tribe objects have been loaded
    if (!currentUser.loadedInitialTribes)
        return 0;

    Tribe * tribe = [currentUser.tribes objectAtIndex:section];
    return [tribe[@"habits"] count];
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
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDataSource

- (void)configureCell:(MCSwipeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    // makes sure tribe objects have been loaded
    if (!currentUser.loadedInitialTribes)
        return;
    
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.section];
    Habit * habit = [tribe[@"habits"] objectAtIndex:indexPath.row];
    
    // cell modifications that go for both complete/uncomplete tribes
    [self configureCellForAllTribes:cell withHabit:habit];
    
    // cell modifications depending on completion/uncompleted
    if ([habit completedForDay]) {
        [self configureCellForCompletedTribeHabit:cell withTribe:tribe andHabit:habit];
    } else {
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
    
    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {

        [currentUser completeActivityForHabit:habit inTribe:tribe];
        [self makeItRainConfetti];
        [self updateProgressBar];
        [self playSound:@"completion-sound" :@".mp3"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.section];
    Habit * habit = [tribe[@"habits"] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showTribeHabit" sender:habit];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
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
    
    Tribe * tribe = [currentUser.tribes objectAtIndex:section];
    [titleLabel setText:tribe[@"name"]];
    
    // create label for 🦁 or 🐑
    UILabel * lionOrSheepTribe = [[UILabel alloc] init];
    [lionOrSheepTribe setFrame:CGRectMake(337, 35, 40, 40)];
    [lionOrSheepTribe setText:@"🦁"];
    
    // check if al members completed all habits to set
    lionOrSheepTribe.text = ([tribe allHabitsAreCompleted]) ? @"🦁" : @"🐑" ;
    
    // add labels to header view
    [headerView addSubview:lionOrSheepTribe];
    [headerView addSubview:titleLabel];

    return headerView;
}

-(void)sectionHeaderTap:(id)section {
    NSLog(@"%@", section);
    
}
#pragma mark - MCSwipeTableViewCellDelegate


// When the user starts swiping the cell this method is called
- (void)swipeTableViewCellDidStartSwiping:(MCSwipeTableViewCell *)cell {
//     NSLog(@"Did start swiping the cell!");
}

// When the user ends swiping the cell this method is called
- (void)swipeTableViewCellDidEndSwiping:(MCSwipeTableViewCell *)cell {
//     NSLog(@"Did end swiping the cell!");
}

// When the user is dragging, this method is called and return the dragged percentage from the border
- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didSwipeWithPercentage:(CGFloat)percentage {
//     NSLog(@"Did swipe with percentage : %f", percentage);
}
#pragma mark - User login/signup

-(void)signUp {

    UINavigationController * SignUpLoginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignUpLoginViewController"];
    [self.navigationController presentViewController:SignUpLoginViewController animated:YES completion:nil];
}

#pragma mark - Segue handling

-(IBAction)unwindFromAddTribe:(UIStoryboardSegue *)segue {
    
    // reload tableview after added new tribe
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"showTribeHabit"]) {
        
        // get tribe VC to set the tribe
        TribeDetailTableViewController * tribeDetailVC = segue.destinationViewController;
        
        // sender contains tribe tapped
        tribeDetailVC.habit = sender;
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
    
    // add pull to refresh control
    [self addPullToRefresh];
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleEnteredForeground) name:UIApplicationDidBecomeActiveNotification object: nil];
    
    // set table section height (tribe height)
    self.tableView.sectionHeaderHeight = 100;
}

-(void)handleEnteredForeground {
    [self refreshTable];
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
    refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
}
-(void)refreshTable {
    [currentUser loadTribesWithBlock:^{
        [refreshControl endRefreshing];
        [self.tableView reloadData];
        [self updateProgressBar];
    }];
}


#pragma mark - Progress Bar

-(void)addProgressBar {
    
    // set up progr
    progressBar = [[YLProgressBar alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,10)];
    progressBar.type                = YLProgressBarTypeFlat;
    progressBar.trackTintColor      = [UIColor clearColor];
    progressBar.progressTintColor   = [UIColor colorWithRed:105.0/255.0 green:203.0/255.0 blue:149.0/255.0 alpha:1.0];
    progressBar.trackTintColor      = [UIColor lightGrayColor];
    progressBar.indicatorTextLabel.text  = @"";
    progressBar.hideGloss           = YES;
    progressBar.hideStripes         = YES;
    progressBar.indicatorTextDisplayMode = YLProgressBarIndicatorTextDisplayModeTrack;
    [self.tableView addSubview:progressBar];
    
    [self updateProgressBar];
    
}
-(void)updateProgressBar {
    
    float numberOfTribes = (float)currentUser.tribes.count;
    float completionProgress = 100.0/numberOfTribes;
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









