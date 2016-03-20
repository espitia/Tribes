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


#pragma mark - Loading methods

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
            NSLog(@"2. successfully loaded all habits for tribe");
            
            [self loadMembersWithBlock:^(bool success) {
                
                if (success) {
                    NSLog(@"3. successfully loaded all memebers");
                    
                    [self loadActivitiesWithBlock:^(bool success) {
                        if (success) {
                            NSLog(@"4. successfully loaded all activities");
                            callback(true);
                        } else {
                            NSLog(@"failed to load activities");
                            callback(false);
                        }
                    }];
                    
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
        NSLog(@"found habits for tribe. will attempt to load first from local datastore.");
        
                __block int counter = 0;
        for (Habit * habit in self.habits) {
            
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
                    

                    [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded && !error) {
                            
                            NSLog(@"successfully pinned members");
                            
                            // add members to tribe.tribeMembers
                            [self addTribeMembersToTribe:objects];
                            // add members to habits.members
                            [self addTribeMembersToHabits:objects];
                            
                            callback(true);
                        } else {
                            NSLog(@"failed to pin members");
                            callback(false);
                        }
                    }];

                    
                } else {
                    NSLog(@"failed to load members from network");
                    callback(false);
                }
            }];
        }
        
    }];
    
}

-(void)loadActivitiesWithBlock:(void(^)(bool success))callback {

    if (!tribeMembers || tribeMembers.count <= 0) {
        NSLog(@"Error accessing members when attempting to load activities");
        callback(false);
    }
    
    // iterate through every member and load their activities
    __block int memberCounter = 0;
    for (User * member in tribeMembers) {
        __block int activityCounter = 0;
        for (Activity * activity in member.activities) {
            
            [activity fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                if (object && object.createdAt && !error) {
                    NSLog(@"successfully fetched activity from local data store");
                    
                    activityCounter++;
                    
                    if (activityCounter == member.activities.count) {
                        memberCounter++;
                        if (memberCounter == tribeMembers.count) {
                            callback(true);
                        }
                    }
                } else {
                    NSLog(@"Failed to fetch activity from local data store. will attempt to fetch from network");
                    
                    [activity fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (object && object.createdAt && !error) {
                            NSLog(@"successfully fetched activity from network");
                            [object pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                if (succeeded && !error) {
                                    NSLog(@"successfully pinned activity");
                                    
                                    activityCounter++;
                                    
                                    if (activityCounter == member.activities.count) {
                                        memberCounter++;
                                        if (memberCounter == tribeMembers.count) {
                                            callback(true);
                                        }
                                    }
                                } else {
                                    NSLog(@"failed to pin activity");
                                    callback(false);
                                }
                            }];
                            
                        } else {
                            NSLog(@"failed to fetch activity from network.");
                            callback(false);
                        }
                    }];
                    
                    
                }
            }];
            
            
        }
    }
    
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

#pragma mark - Updating methods

-(void)updateTribeWithBlock:(void(^)(bool success))callback {
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (object && !error && object.createdAt) {
            NSLog(@"successfully fetched tribe from network");
            // pin to local datastore
            [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (!error && succeeded) {
                    NSLog(@"succesfully pinned tribe.");
                    
                    [self updateHabitsWithBlock:^(bool success) {
                        if (success) {
                            [self updateMembersWithBlock:^(bool success) {
                                if (success) {
                                    [self updateActivitiesWithBlock:^(bool success) {
                                        if (success) {
                                            NSLog(@"successfully updated tribe");
                                            callback(true);
                                        } else {
                                            NSLog(@"failed to update activities");
                                            callback(false);
                                        }
                                    }];
                                } else {
                                    NSLog(@"failed to update members");
                                    callback(false);
                                }
                            }];
                        } else {
                            NSLog(@"failed to update members");
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

-(void)updateHabitsWithBlock:(void(^)(bool success))callback {
    // first check if there are habits to load
    if (self.habits.count > 0) {
        
        [PFObject fetchAllInBackground:self.habits block:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            
            if (objects && !error) {
                NSLog(@"successfully fetched habits to update");
                [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                    
                    if (succeeded && !error) {
                        NSLog(@"successfully pinned habits to update");
                        callback(true);
                    } else {
                        NSLog(@"failed to pin habits to update");
                        callback(false);
                    }
                    
                }];
            } else {
                NSLog(@"failed to fetch habits to update");
                callback(false);
            }
        }];

    } else {
        NSLog(@"no habits found for tribe");
        callback(true);
    }
    
}

-(void)updateMembersWithBlock:(void(^)(bool success))callback {
    PFRelation * relationToMembersToFetchFromNetwork = [self relationForKey:@"members"];
    PFQuery * query = [relationToMembersToFetchFromNetwork query];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (!error && objects && [self allMembersFullyLoaded:objects]) {
            NSLog(@"succesfully fetched members from network");
            
            [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded && !error) {
                    NSLog(@"successfully pinned members");
                    
                    // add members to tribe.tribeMembers
                    [self addTribeMembersToTribe:objects];
                    // add members to habits.members
                    [self addTribeMembersToHabits:objects];
                    
                    callback(true);
                } else {
                    NSLog(@"failed to pin members");
                    callback(false);
                }
            }];
            
        } else {
            NSLog(@"failed to load members from network");
            callback(false);
        }
    }];
    
}

-(void)updateActivitiesWithBlock:(void(^)(bool success))callback {
    if (!tribeMembers || tribeMembers.count <= 0) {
        NSLog(@"Error accessing members when attempting to load activities");
        callback(false);
    }
    
    // get all members in one array to fetch their activities
    NSMutableArray * activitiesOfAllMembers = [[NSMutableArray alloc] init];
    NSMutableArray * objectIdsOfAllActivities = [[NSMutableArray alloc] init];
    
    // get activity objects
    for (User * member in self.tribeMembers) {
        [activitiesOfAllMembers addObjectsFromArray:member.activities];
    }
    // get activity object Ids
    for (Activity * activity in activitiesOfAllMembers) {
        NSString * objectId = activity.objectId;
        [objectIdsOfAllActivities addObject:objectId];
    }
    
    PFQuery * query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"objectId" containedIn:objectIdsOfAllActivities];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (objects && !error) {
            NSLog(@"succesfully fetched activities");
            [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded && !error) {
                    NSLog(@"succesfully pinned all activiteS");
                    [self addActivitiesToMembers:objects];
                    callback(true);
                } else {
                    NSLog(@"failed to pin activities");
                    callback(false);
                }
            }];
            
        } else {
            NSLog(@"failed to query all activities");
            callback(false);
        }
        
    }];
    
}

-(void)addActivitiesToMembers:(NSArray *)activities {
    NSMutableArray * members = [[NSMutableArray alloc] init];
    for (User * member in self.tribeMembers) {
        [member.activities removeAllObjects];
        [members addObject:member];
    }
    for (User * member in members) {
        for (Activity * activity in activities) {
            if (activity[@"createdBy"] == member) {
                [member.activities addObject:activity];
            }
        }
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

-(void)addHabitToTribeWithName:(NSString *)name andBlock:(void(^)(bool success))callback {

    // cloud code to add habit and create activites for each user in tribe
    [PFCloud callFunctionInBackground:@"addActivitiesToUsersOfTribe"
                       withParameters:@{@"tribeObjectID":self.objectId,
                                        @"newHabitName":name}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                                                    
                                            if (error) {
                                                callback(false);
                                            } else {
                                                callback(true);
                                            }
                                        }];
    
}


@end
