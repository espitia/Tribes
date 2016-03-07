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
        
        if (error || !object) {
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

#pragma mark - Update methods

-(void)updateMemberActivitiesWithBlock:(void(^)(void))callback  {
    __block int counter = 0;
    for (User * member in tribeMembers) {
        [member updateActivitiesWithBlock:^{
            counter++;
            if (counter == [tribeMembers count]) {
                NSLog(@"successfuly updated all member activites object from network.");
                callback();
            }
        }];
    }
    
}

-(void)updateHabitsWithBlock:(void(^)(void))callback {
    __block int counter = 0;
    for (Habit * habit in self[@"habits"]) {
        counter++;
        [habit updateHabitWithBlock:^{
            if (counter == [self[@"habits"] count]) {
                callback();
            }
        }];
    }
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



#pragma mark - Habits loading and updating

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

#pragma mark - Members loading and updating


-(void)loadMembersWithBlock:(void(^)(void))callback {

    PFRelation * relation = [self relationForKey:@"members"];
    PFQuery * query = [relation query];
    [query fromLocalDatastore];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (error || !objects || objects.count == 0) {
            [self updateMembersWithBlock:^{
                callback();
            }];
        } else {
            tribeMembers = [NSMutableArray arrayWithArray:objects];
            callback();
        }
    }];
}

-(void)updateMembersWithBlock:(void(^)(void))callback {
    
    PFRelation * relation = [self relationForKey:@"members"];
    PFQuery * query = [relation query];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error updating members");
            
        } else {
            NSLog(@"successfuly members for tribe from network.");
            tribeMembers = [NSMutableArray arrayWithArray:objects];
            [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                callback();
            }];
        }
        
    }];    
}

-(void)addTribeMembersToHabits:(NSArray *)membersToAdd {
    for (Habit * habit in self[@"habits"]) {
        habit.members = [NSMutableArray arrayWithArray:membersToAdd];
    }
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
                                                // save tribe
                                                [self saveInBackground];
                                                callback(&success);
                                            }
                                        }];

}

-(BOOL)userAlreadyInTribe:(PFUser *)user {
    return ([self.tribeMembers containsObject:user]) ? true : false;
}

#pragma mark - Checking statuses of membs/activities

-(BOOL)membersAndActivitesAreLoaded {
    return (self.membersAndActivities.count == 0 || !self.membersAndActivities) ? false : true;
}

#pragma mark - State of Tribe

-(BOOL)allHabitsAreCompleted {
    for (Habit * habit in self[@"habits"]) {
        if (!habit.allMembersCompletedActivity) {
            return false;
        }
    }
    return true;
}


@end
