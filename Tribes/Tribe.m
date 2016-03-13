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

-(void)loadTribeWithMembersAndHabitsWithBlock:(void(^)(void))callback {
    
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error || !object) {
            NSLog(@"error fetching tribe from local storage.\n will try to fetch from network.");
            callback();
        } else {

            [self loadHabitsWithBlock:^ {
                [self loadMembersWithBlock:^ {
                    [self loadMemberActivitiesWithBlock:^{
                        callback();
                    }];
                }];
            }];
        }
    }];
    
}


-(void)loadMemberActivitiesWithBlock:(void(^)(void))callback  {
    
    __block int counter = 0;
    for (User * member in tribeMembers) {
        [member loadActivitiesWithBlock:^{
            counter++;
            if (counter == [tribeMembers count]) {
                [self addTribeMembersToHabits];
                callback();
            }
        }];
    }
    
}

-(void)updateMemberActivitiesWithBlock:(void(^)(void))callback  {
    __block int counter = 0;
    for (User * member in tribeMembers) {
        [member updateActivitiesWithBlock:^{
            counter++;
            if (counter == [tribeMembers count]) {
                NSLog(@"successfuly updated all member activites object from network.");
                [self addTribeMembersToHabits];
                callback();
            }
        }];
    }
    
}

-(void)loadHabitsWithBlock:(void(^)(void))callback  {
    __block int counter = 0;
    
    if (!self.habits)
        callback();
    
    for (Habit * habit in self[@"habits"]) {
        [habit loadWithBlock:^{
            counter++;
            if (counter == [self[@"habits"] count]) {
                callback();
            }
        }];
    }
    
}


-(void)updateHabitsWithBlock:(void(^)(void))callback {
    __block int counter = 0;
    
    if (!self.habits)
        callback();
    
    for (Habit * habit in self[@"habits"]) {
        counter++;
        [habit updateHabitWithBlock:^{
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
            callback();
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

-(void)addTribeMembersToHabits {
    for (Habit * habit in self[@"habits"]) {
        habit.members = [NSMutableArray arrayWithArray:self.tribeMembers];
    }
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
                                                // save tribe
                                                [self saveInBackground];
                                                callback(&success);
                                            }
                                        }];
    
}


@end
