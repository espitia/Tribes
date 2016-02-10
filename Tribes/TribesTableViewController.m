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
#import "YLProgressBar.h"

@interface TribesTableViewController () <MCSwipeTableViewCellDelegate> {
    User * currentUser;
    UIRefreshControl * refreshControl;
    YLProgressBar * progressBar;
}

@end

@implementation TribesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set currentUser
    currentUser = [User currentUser];
    
    // register table view cell
    [self.tableView registerClass:[MCSwipeTableViewCell class] forCellReuseIdentifier:@"TribeCell"];
    
    // add pull to refresh control
    [self addPullToRefresh];
    
    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
        
        self.navigationItem.title = @"Loading Tribes..";
        
        [currentUser loadTribesWithBlock:^{
            //            self.navigationItem.title = [NSString stringWithFormat:@"lvl %d - %dxp", currentUser.lvl, currentUser.xp];
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
    [cell.textLabel setText:tribe[@"name"]];
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
    
    // Setting the default inactive state color to the tableView background color
    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    [cell setDelegate:self];
    
    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {

        [currentUser completeActivityForTribe:tribe];
        [self updateProgressBar];
//        [self showAlertWithTitle:@"🔑🔑🔑" andMessage:@"+ 100xp"];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"TribeDetail" sender:[currentUser.tribes objectAtIndex:indexPath.row]];
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
    if ([segue.identifier isEqualToString:@"TribeDetail"]) {
        
        // initiate tribedetailvc
        TribeDetailTableViewController * tribeDetailVC = (TribeDetailTableViewController *)segue.destinationViewController;
        // sender contains tribe tapped
        tribeDetailVC.tribe = sender;
    }
}

#pragma mark - Helper methods



- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
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
    }];
}

#pragma mark - Alerts

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

-(void)addProgressBar {

    // colors
    NSArray *rainbowColors = @[[UIColor colorWithRed:33/255.0f green:180/255.0f blue:162/255.0f alpha:1.0f],
                               [UIColor colorWithRed:3/255.0f green:137/255.0f blue:166/255.0f alpha:1.0f],
                               [UIColor colorWithRed:91/255.0f green:63/255.0f blue:150/255.0f alpha:1.0f],
                               [UIColor colorWithRed:87/255.0f green:26/255.0f blue:70/255.0f alpha:1.0f],
                               [UIColor colorWithRed:126/255.0f green:26/255.0f blue:36/255.0f alpha:1.0f],
                               [UIColor colorWithRed:149/255.0f green:37/255.0f blue:36/255.0f alpha:1.0f],
                               [UIColor colorWithRed:228/255.0f green:69/255.0f blue:39/255.0f alpha:1.0f],
                               [UIColor colorWithRed:245/255.0f green:166/255.0f blue:35/255.0f alpha:1.0f],
                               [UIColor colorWithRed:165/255.0f green:202/255.0f blue:60/255.0f alpha:1.0f],
                               [UIColor colorWithRed:202/255.0f green:217/255.0f blue:54/255.0f alpha:1.0f],
                               [UIColor colorWithRed:111/255.0f green:188/255.0f blue:84/255.0f alpha:1.0f]];
    
    progressBar = [[YLProgressBar alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,5)];
    progressBar.type                = YLProgressBarTypeFlat;
    progressBar.trackTintColor      = [UIColor clearColor];
    progressBar.progressTintColors   = rainbowColors;
    progressBar.hideGloss           = YES;
    progressBar.hideStripes         = YES;
    progressBar.indicatorTextDisplayMode = YLProgressBarIndicatorTextDisplayModeTrack;
    [self.tableView addSubview:progressBar];
    
    [self updateProgressBar];
    
}
-(void)updateProgressBar {
    
    float numberOfTribes = (float)currentUser.tribes.count;
    float completionProgress = 100/numberOfTribes;
    float completions;
    for (Activity * activity in currentUser.activities) {
        if ([activity completedForDay]) {
            completions++;
        }
    }
    float totalProgress = (completionProgress * completions) * .01 ;
    [progressBar setProgress:totalProgress animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // add offset to progress bar frame so it doesn't move
    CGRect frame = progressBar.frame;
    frame.origin.y = scrollView.contentOffset.y + 64;
    [progressBar setFrame:frame];
    [self.view bringSubviewToFront:progressBar];
}

@end









