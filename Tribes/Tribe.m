//
//  Tribe.m
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Tribe.h"
#import "Activity.h"
#import "User.h"
#import "Habit.h"
#import <Parse/PFObject+Subclass.h>


@implementation Tribe

@dynamic name;
@synthesize membersAndActivities;
@synthesize tribeMembers;
@synthesize habits;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Tribe";
}

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Loading methods

-(void)loadTribeWithMembersAndHabitsWithBlock:(void(^)(void))callback {
    
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error fetching tribe from local storage.\n will try to fetch from network.");
            
            [self updateTribeWithBlock:^{
                [self loadHabitsWithBlock:^ {
                    [self loadMembersWithBlock:^{
                        [self loadMemberActivitiesWithBlock:^{
                            [self addTribeMembersToHabits];
                            callback();
                        }];
                    }];
                }];
            }];
            
        } else {

            [self loadHabitsWithBlock:^ {
                [self loadMembersWithBlock:^ {
                    [self loadMemberActivitiesWithBlock:^{
                        [self addTribeMembersToHabits];
                        callback();
                    }];
                }];
            }];
        }
    }];
    
}

-(void)addTribeMembersToHabits {
    for (Habit * habit in self[@"habits"]) {
        habit.members = [NSMutableArray arrayWithArray:self.tribeMembers];
    }
}

-(void)loadMemberActivitiesWithBlock:(void(^)(void))callback  {
    
    __block int counter = 0;
    for (User * member in tribeMembers) {
        [member loadActivitiesWithBlock:^{
            counter++;
            if (counter == [tribeMembers count]) {
                callback();
            }
        }];
    }
    
}

-(void)loadHabitsWithBlock:(void(^)(void))callback  {
    __block int counter = 0;
    for (Habit * habit in self[@"habits"]) {
        [habit loadWithBlock:^{
            counter++;
            if (counter == [self[@"habits"] count]) {
                callback();
            }
        }];
    }
    
}

-(void)loadMembersWithBlock:(void(^)(void))callback {

    PFRelation * relation = [self relationForKey:@"members"];
    PFQuery * query = [relation query];
    [query fromLocalDatastore];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (error || !objects || objects.count == 0) {
            [self updateMembersWithBlock:^{
                tribeMembers = [NSMutableArray arrayWithArray:objects];;
                callback();
            }];
        } else {
            tribeMembers = [NSMutableArray arrayWithArray:objects];
            callback();
        }
    }];
}

-(void)addTribeMembersToHabits:(NSArray *)membersToAdd {
    for (Habit * habit in self[@"habits"]) {
        habit.members = [NSMutableArray arrayWithArray:membersToAdd];
    }
}

-(void)updateMembersWithBlock:(void(^)(void))callback {
    
    PFRelation * relation = [self relationForKey:@"members"];
    PFQuery * query = [relation query];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error updating members");
            
        } else {
            NSLog(@"updated members from local storage.");
            [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                callback();
            }];
        }
        
    }];    
}

-(void)updateTribeWithBlock:(void(^)(void))callback {
    
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error updating tribe from network.");
        } else {
            NSLog(@"successfuly updated tribe object from network.");
            
            [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                callback();
            }];
        }
    }];
    
}


#pragma mark - Handling users in Tribe

/**
 * Adds a user to tribe's member relation. Then it calls PFCloud code to add tribe, create activity objet and add activity to user.
 *
 * @param User to be added to tribe
 * @return A BOOl value of true or false to let you know if everything went smoothly.
 */
-(void)addUserToTribe:(PFUser *)user withBlock:(void (^)(BOOL * success))callback {
    
    // add user to member relation
    PFRelation * memberRelationToTribe = [self relationForKey:@"members"];
    [memberRelationToTribe addObject:user];
    
    // save tribe
    [self saveInBackground];
    
    __block BOOL success;
    
    // cloud code to add tribe and activity to user (then save user)
    [PFCloud callFunctionInBackground:@"addTribeAndActivityToUser"
                       withParameters:@{@"tribeObjectID":self.objectId,
                                        @"userObjectID":user.objectId
                                        } block:^(id  _Nullable object, NSError * _Nullable error) {

                                            if (error) {
                                                success = false;
                                                callback(&success);
                                            } else {
                                                success = true;
                                                callback(&success);
                                            }
                                        }];

}

-(BOOL)userAlreadyInTribe:(PFUser *)user {
    return ([self.tribeMembers containsObject:user]) ? true : false;
}

#pragma mark - Push notifications to Tribe members

-(void)sendTribe100PercentCompletedPush {
    NSString * message = [NSString stringWithFormat:@"%@ 💯 - All tribe members completed the activity ✊", self[@"name"]];
    [self sendPushToAllMembersWithMessage:message andCategory:nil];
}

-(void)sendPushToAllMembersWithMessage:(NSString *)message andCategory:(NSString *)category {
    for (User * user in self.tribeMembers) {
        [self sendPushToMember:user WithMessage:message andCategory:category];
    }
}

/**
 * Send push to a member in tribe with category for push notification replys.
 
 @param member Member to send push to.
 @param msg message to send member
 @param category the category of reply actions that will be available to the recepient of the push: "MOTIVATION_REPLY", "COMPLETION_REPLY". !!! LEAVE EMPTY STRING IN ORDER TO NOT HAVE ANY REPLY OPTIONS"
 */

-(void)sendPushToMember:(User *)member WithMessage:(NSString *)message andCategory:(NSString *)category {
    
    // security check: if category is anything but the accepeted categories, default to no categories
    if (!(category || ([category isEqualToString:@"COMPLETION_REPLY"]) || ([category isEqualToString:@"MOTIVATION_REPLY"]))) {
        category = @"";
    }
    
    // cloud code to send push
    [PFCloud callFunctionInBackground:@"sendPush"
                       withParameters:@{@"receiverId":member.objectId,
                                        @"msg":message,
                                        @"category":category}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    
                                    if (error) {
                                        NSLog(@"error:\n %@", error);
                                    } else {
                                        NSLog(@"success:\n%@", object);

                                    }
                                    
                                }];
}

#pragma mark - Sorting members by activity
/**
 * Sorts members and activities array by total completions.
 */
-(void)sortMembersAndActivitiesByTotalActivityCompletions {
    [self sortMembersAndActivitiesBy:@"total"];
}
/**
 * Sorts members and activities array by weekly completions.
 */
-(void)sortMembersAndActivitiesByWeeklyActivityCompletions {
    [self sortMembersAndActivitiesBy:@"weekly"];
}

/**
 * Sorts members and activities array by indicated time frame.
 *
 * @param timeFrame time frame to sort by, use key "total" or "weekly"
 */
-(void)sortMembersAndActivitiesBy:(NSString *)timeFrame {
    
    NSString * sortByKey;
    
    if ([timeFrame isEqualToString:@"total"]) {
        sortByKey = @"activity.completions";
    } else if ([timeFrame isEqualToString:@"weekly"]) {
        sortByKey = @"activity.weekCompletions";
    } else {
        sortByKey = @"activity.completions"; // default to catch any errors
    }
        
    NSArray * sortedArrayByActivityCompletions = [[NSArray alloc] init];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:sortByKey  ascending:NO];
    sortedArrayByActivityCompletions = [self.membersAndActivities sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    self.membersAndActivities = [NSMutableArray arrayWithArray:sortedArrayByActivityCompletions];
}


#pragma mark - Checking statuses of membs/activities

-(BOOL)membersAndActivitesAreLoaded {
    return (self.membersAndActivities.count == 0 || !self.membersAndActivities) ? false : true;
}

-(BOOL)allMembersCompletedActivity {
    for (Activity * activity in self.activities) {
        if (![activity completedForDay]) {
            if (!activity.hibernation) {
                return false;
            }
        }
    }
    return true;
}

@end
