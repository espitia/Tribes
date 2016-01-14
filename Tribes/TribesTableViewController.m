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

@interface TribesTableViewController () {
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
    
    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
        [self loadTribes];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeCell" forIndexPath:indexPath];
    
    PFObject * tribe = _tribes[indexPath.row];
    cell.textLabel.text = tribe[@"name"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject * tribeTapped = [_tribes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"TribeDetail" sender:tribeTapped];
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

-(void)loadTribes {
    
    NSArray * tribes = currentUser[@"tribes"];
    
    for (PFObject * tribe in tribes) {
        PFQuery * query = [PFQuery queryWithClassName:@"Tribe"];
        [_tribes addObject:[query getObjectWithId:tribe.objectId]];
        [self.tableView reloadData];
    }
    

    [self loadMembersOfTribeWithActivities:_tribes[0]];
}

/**
 * Load members of a tribe with their corresponding activity
 *
 * @param tribe from which you want to retrieve members and activities
 * @return A neat dictionary with 2 keys, "member" with a PFUser object and
 * "activity" with a PFObject of class type Activity
 */
-(NSMutableArray *)loadMembersOfTribeWithActivities:(PFObject *)tribe {
    
    NSMutableArray * membersAndActivities = [[NSMutableArray alloc] init];
    __block NSMutableArray * membersArray;
    __block NSMutableArray * activitiesArray;
    
    // get array of members
    [self getMembersFromTribe:tribe withBlock:^(NSArray *members) {
        
        // asign members to array to later add to dictionary
        membersArray = [NSMutableArray arrayWithArray:members];
        
        // get activities for each member according to tribe passed
        [self getActivitiesOfMembers:membersArray forTribe:tribe withBlock:^(NSArray * activities) {
            activitiesArray = [NSMutableArray arrayWithArray:activities];
            
            for (PFUser * member in membersArray) {
                for (PFObject * activity in activitiesArray) {
                    
                    NSDictionary * memberAndActivity = @{
                                                         @"member":member,
                                                         @"activity":activity,
                                                         };
                    [membersAndActivities addObject:memberAndActivity];
                }
            }


        }];
        
    }];
    
    return membersAndActivities;
}
-(void)getActivitiesOfMembers:(NSMutableArray *)members forTribe:(PFObject *)tribe withBlock:(void(^)(NSArray * activites))callback {

    NSMutableArray * activities = [[NSMutableArray alloc] init];
    
    // get activity where createdBy = member and tribe.objID = tribe.objID
    for (PFUser * member in members) {
        
        // get activity object by matching createdBy key to user and tribe key equals to corresponding tribe
        PFQuery * query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"createdBy" equalTo:member];
        [query whereKey:@"tribe" equalTo:tribe];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            if (!error) {
                [activities addObject:object];
            } else {
                NSLog(@"error: %@", error);
            }
            
            // return activities when each member has an activity
            if (activities.count == members.count) {
                callback(activities);
            }
        }];
    }
}

-(void)getMembersFromTribe:(PFObject *)tribe withBlock:(void(^)(NSArray * members))callback {

    // array to hold members
    NSMutableArray * membersPlaceholderArray = [[NSMutableArray alloc] init];
    
    // get relation of tribe object to the members
    PFRelation * membersOfTribeRelation = tribe[@"members"];
    
    // query that relation for the objects (members)
    PFQuery * queryForMembersOfTribe = [membersOfTribeRelation query];
    
    // get member objects
    [queryForMembersOfTribe findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {

            // add user objects into members var
            [membersPlaceholderArray addObjectsFromArray:objects];
            // send it back
            callback(membersPlaceholderArray);
        } else {
            NSLog(@"error: %@", error);
        }
    }];
    
}
@end









