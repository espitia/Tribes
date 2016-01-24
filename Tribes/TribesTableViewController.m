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

@interface TribesTableViewController () <MCSwipeTableViewCellDelegate> {
    PFUser * currentUser;
}

@end

@implementation TribesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // set currentUser
    currentUser = [PFUser currentUser];
    
    // init instance/public variables needed
    _tribes = [[NSMutableArray alloc] init];
    
    // register table view cell
    [self.tableView registerClass:[MCSwipeTableViewCell class] forCellReuseIdentifier:@"TribeCell"];

    
    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
        [self loadTribes];
    }

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TribeCell";
    
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TribeCell"];
        
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
    
    Tribe * tribe = [_tribes objectAtIndex:indexPath.row];

    UIView *checkView = [self viewWithImageName:@"check"];
    UIColor *greenColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
    
    // Setting the default inactive state color to the tableView background color
    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    [cell setDelegate:self];
    
    [cell.textLabel setText:tribe[@"name"]];
    [cell.detailTextLabel setText:@"German D 🔑"];
    
    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        NSLog(@"Did swipe \"Checkmark\" cell");
    }];
    
    
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"TribeDetail" sender:[_tribes objectAtIndex:indexPath.row]];
}

#pragma mark - MCSwipeTableViewCellDelegate


// When the user starts swiping the cell this method is called
- (void)swipeTableViewCellDidStartSwiping:(MCSwipeTableViewCell *)cell {
    // NSLog(@"Did start swiping the cell!");
}

// When the user ends swiping the cell this method is called
- (void)swipeTableViewCellDidEndSwiping:(MCSwipeTableViewCell *)cell {
    // NSLog(@"Did end swiping the cell!");
}

// When the user is dragging, this method is called and return the dragged percentage from the border
- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didSwipeWithPercentage:(CGFloat)percentage {
    // NSLog(@"Did swipe with percentage : %f", percentage);
}
#pragma mark - User login/signup

-(void)signUp {

//    [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    SignupViewController * signupVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    [self.navigationController presentViewController:signupVC animated:false completion:nil];
}

#pragma mark - Segue handling

-(IBAction)unwindFromAddTribe:(UIStoryboardSegue *)segue {
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

/**
 * Load current user to fetch if any new tribes were added,
 * then fetch all tribes he/she is in.
 *
 */
-(void)loadTribes {
    
    // update user in case other users added him/her to a tribe
    [currentUser fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error loading user: %@", error);
        } else {
            // get freshly updated tribes
            NSArray * tribes = currentUser[@"tribes"];
            
            for (Tribe * tribe in tribes) {
                
                // load tribe objects
                [tribe fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    
                    if (error) {
                        NSLog(@"error loading tribes: %@", error);
                    } else {
                        [_tribes addObject:object];
                        [self.tableView reloadData];
                    }
                    
                }];
                
            }

        }
    }];
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}



@end









