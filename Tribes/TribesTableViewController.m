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
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        currentUser = (User *)object;
        //  log in / sign up user if non-existent
        if (!currentUser) {
            SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
            NSString * msg = [NSString stringWithFormat:@"%@", currentUser];
            [alert showError:@"Error msg" subTitle:msg closeButtonTitle:@"OK" duration:0.0];
            [self signUp];
        } else {
            
            //set up
            [self setUp];
            
            self.navigationItem.title = @"Loading Tribes..";
            
            [currentUser loadTribesWithBlock:^{
                //            self.navigationItem.title = [NSString stringWithFormat:@"lvl %d - %dxp", currentUser.lvl, currentUser.xp];
                self.navigationItem.title = @"Tribes";
                [self.tableView reloadData];
                
                // add and update progress bar
                [self addProgressBar];
            }];
        }
    }];
}

-(void)viewDidAppear:(BOOL)animated {
    
    // security check
    if (!currentUser)
        currentUser = [User currentUser];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return currentUser.tribes.count;
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
    
    Tribe * tribe = [currentUser.tribes objectAtIndex:indexPath.row];
    Activity * activity = [currentUser activityForTribe:tribe];
    
    // cell modifications that go for both complete/uncomplete tribes
    [self configureCellForAllTribes:cell withTribe:tribe];
    
    // cell modifications depending on completion/uncompleted
    if ([activity completedForDay]) {
        [self configureCellForCompletedTribeActivity:cell withTribe:tribe];
    } else {
        [self configureCellForUncompleteTribeActivity:cell withTribe:tribe atIndexPath:indexPath];
    }
    
}

- (void)configureCellForAllTribes:(MCSwipeTableViewCell *)cell withTribe:(Tribe *)tribe  {
    
    // set name of tribe
    [cell.textLabel setText:tribe[@"name"]];
    
    // Setting the default inactive state color to the tableView background color
    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    // set delegate
    [cell setDelegate:self];
    
    UIView *crossView = [self viewWithImageName:@"cross"];
    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];

    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        [alert addButton:@"CONFIRM" actionBlock:^(void) {
            [currentUser removeFromTribe:tribe];
            [self updateProgressBar];
            [self.tableView reloadData];
        }];
        [alert showError:@"❌" subTitle:@"Are you sure you want to leave\nthe Tribe?" closeButtonTitle:@"NEVER MIND" duration:0.0];

    }];

}
- (void)configureCellForCompletedTribeActivity:(MCSwipeTableViewCell *)cell withTribe:(Tribe *)tribe  {
   
    // set detail text depending on whether all tribe members completed their activity
    NSString * detailText = ([tribe allMembersCompletedActivity]) ? @"✅🦁" : @"✅🐑" ;
    [cell.detailTextLabel setText:detailText];
    
    NSDictionary* attributes = @{NSStrikethroughStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleSingle]};
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:tribe.name attributes:attributes];
    
    cell.textLabel.attributedText = attributedString;
}

- (void)configureCellForUncompleteTribeActivity:(MCSwipeTableViewCell *)cell withTribe:(Tribe *)tribe atIndexPath:(NSIndexPath *)indexPath {
    
    // set detail text depending on whether all tribe members completed their activity
    NSString * detailText = @"❌🐑" ;
    [cell.detailTextLabel setText:detailText];
    
    UIView *checkView = [self viewWithImageName:@"check"];
    UIColor *greenColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
    
    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {

        [currentUser completeActivityForTribe:tribe];
        [self makeItRainConfetti];
        [self updateProgressBar];
        [self playSound:@"completion-sound" :@".mp3"];
//        [self showAlertWithTitle:@"🔑🔑🔑" andMessage:@"+ 100xp"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"showTribe" sender:[currentUser.tribes objectAtIndex:indexPath.row]];
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

//    [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    SignupViewController * signupVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    [self.navigationController presentViewController:signupVC animated:false completion:nil];
}

#pragma mark - Segue handling

-(IBAction)unwindFromAddTribe:(UIStoryboardSegue *)segue {
    
    // reload tableview after added new tribe
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"showTribe"]) {
        
        // get tribe VC to set the tribe
        TribeDetailTableViewController * tribeDetailVC = segue.destinationViewController;
        
        // sender contains tribe tapped
        tribeDetailVC.tribe = sender;
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
    progressBar = [[YLProgressBar alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,5)];
    progressBar.type                = YLProgressBarTypeFlat;
    progressBar.trackTintColor      = [UIColor clearColor];
    progressBar.progressTintColor   = [UIColor greenColor];
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









