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
@dynamic habits;
@synthesize membersAndActivities;
// tribe members is = as members but since members key is a pfrelation, we create another variable to hold array of members
@synthesize tribeMembers;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Tribe";
}

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Loading/Updating methods

-(void)loadTribeWithBlock:(void(^)(bool success))callback {
    
    // fetch tribe from local storage
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (object && !error && object.createdAt) {
            NSLog(@"1. successfully loaded tribe from local datastore");
            
            //continue loading habits -> members -> activites
            [self loadHabitsMembersAndActivities:^(bool success) {
                if (success) {
                    NSLog(@"successfully loaded all habits, members and activities");
                    callback(true);
                } else {
                    NSLog(@"failed to load habits, members and activities");
                    callback(false);
                }
            }];
            
        } else { // if failed to load from local datastore, fetch from network
            NSLog(@"failed to load tribe from local datastore. will try to fetch from network");
            // fetch from network
            [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                if (object && !error && object.createdAt) {
                    NSLog(@"successfully fetched tribe from network");
                    // pin to local datastore
                    [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (!error && succeeded) {
                            NSLog(@"succesfully pinned tribe.");
                            
                            //continue loading habits -> members -> activites
                            [self loadHabitsMembersAndActivities:^(bool success) {
                                if (success) {
                                    NSLog(@"successfully loaded all habits, members and activities");
                                    callback(true);
                                } else {
                                    NSLog(@"failed to load habits, members and activities");
                                    callback(false);
                                }
                            }];
                        } else {
                            NSLog(@"failed to pin tribe");
                            callback(false);
                        }
                    }];
                } else {
                    NSLog(@"failed to fetch tribe from network");
                    callback(false);
                }
            }];
        }
    }];
}
-(void)loadHabitsMembersAndActivities:(void(^)(bool success))callback {
    // attempt to load habits
    [self loadHabitsWithBlock:^(bool success, bool habitsWereAvailable) {
        
        // if attempt successfull and habits are available -> continue to load members and activities
        if (success && habitsWereAvailable) {
            NSLog(@"2. successfully loaded all habits for tribe %@", self);
            
            [self loadMembersWithBlock:^(bool success) {
                if (success) {
                    NSLog(@"loaded all memebers");
                    callback(true);
                } else {
                    NSLog(@"failed to load members");
                    callback(false);
                }
                
            }];
            
        // if attempt successfull but habits are not available -> end loading
        } else if (success && !habitsWereAvailable) {
            NSLog(@"2. tribe does not have habits -> did not continue to load members and activities 👍");
            callback(true);
       
        // if failed attempt, success = false
        } else {
            NSLog(@"failed to load habits");
            callback(false);
        }
    }];
}
-(void)loadHabitsWithBlock:(void(^)(bool success, bool habitsWereAvailable))callback {
    
    // first check if there are habits to load
    if (self.habits.count > 0) {
        NSLog(@"found habits for tribe %@. will attempt to load first from local datastore.", self);
        
        for (Habit * habit in self.habits) {
            
            __block int counter = 0;
            [habit loadHabitWithBlock:^(bool success) {
                
                if (success) {
                    counter++;
                    if (counter == self.habits.count) {
                        NSLog(@"succesfully loaded habits.");
                        callback(true, true);
                    }
                } else {
                    NSLog(@"failed to load habits");
                    callback(false, true);
                }
            }];
        }
    } else {
        NSLog(@"no habits found to load for tribe");
        callback(true, false);
    }
}

-(void)loadMembersWithBlock:(void(^)(bool success))callback {
    
    // first attempt to load members from local datastore
    PFRelation * membersRelation = [self relationForKey:@"members"];
    PFQuery * query = [membersRelation query];
    [query fromLocalDatastore];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (objects && !error && [self allMembersFullyLoaded:objects]) {
            NSLog(@"succesfully loaded all members from local datastore");
            
            // add members to tribe.tribeMembers
            [self addTribeMembersToTribe:objects];
            // add members to habits.members
            [self addTribeMembersToHabits:objects];
            
            callback(true);
        } else {
            
            NSLog(@"failed to load members from local datastore. will atempt fetching from network");
            PFRelation * relationToMembersToFetchFromNetwork = [self relationForKey:@"members"];
            PFQuery * query = [relationToMembersToFetchFromNetwork query];
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                
                if (!error && objects && [self allMembersFullyLoaded:objects]) {
                    NSLog(@"succesfully fetched members from network");
                    
                    // add members to tribe.tribeMembers
                    [self addTribeMembersToTribe:objects];
                    // add members to habits.members
                    [self addTribeMembersToHabits:objects];
                    
                    callback(true);
                    
                } else {
                    NSLog(@"failed to load members from network");
                    callback(false);
                }
                
                
            }];
            
        }
        
    }];
    
}

#pragma mark - Helper methods for Loading

-(BOOL)allMembersFullyLoaded:(NSArray *)members {
    // make sure the key createdAt is loaded -> signifier to being fully loaded
    if (members && members.count > 0) {
        for (PFObject * member in members) {
            if (!member.createdAt) {
                return false;
            }
        }
        return true;
    } else {
        return false;
    }

}

-(void)addTribeMembersToHabits:(NSArray *)membersArray {
    for (Habit * habit in self[@"habits"]) {
        habit.members = [NSMutableArray arrayWithArray:membersArray];
    }
}
-(void)addTribeMembersToTribe:(NSArray *)membersArray {
    self.tribeMembers = [NSMutableArray arrayWithArray:membersArray];
}


#pragma mark - Handling users in Tribe

/**
 * Adds a user to tribe's member relation. Then it calls PFCloud code to add tribe, create activity objet and add activity to user.
 *
 * @param User to be added to tribe
 * @return A BOOl value of true or false to let you know if everything went smoothly.
 */
-(void)addUserToTribe:(PFUser *)user withBlock:(void (^)(BOOL * success))callback {


    
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
 
//                                                [self updateTribeWithBlock:^{
//                                                    callback(&success);
//                                                }];
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
    return false;
}

-(void)addHabitToTribeWithName:(NSString *)name andBlock:(void(^)(BOOL * success))callback {
    

    __block BOOL success;
    
    // cloud code to add habit and create activites for each user in tribe
    [PFCloud callFunctionInBackground:@"addActivitiesToUsersOfTribe"
                       withParameters:@{@"tribeObjectID":self.objectId,
                                        @"newHabitName":name}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                            
                                            if (error) {
                                                success = false;
                                                callback(&success);
                                            } else {
                                                success = true;
                                                callback(&success);
                                            }
                                        }];
    
}


@end
