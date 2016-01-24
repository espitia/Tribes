//
//  Tribe.m
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Tribe.h"
#import <Parse/PFObject+Subclass.h>


@implementation Tribe

@dynamic name;
@synthesize membersAndActivities;
@synthesize members;
@synthesize activities;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Tribe";
}

+ (void)load {
    [self registerSubclass];
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
                                                success = true;
                                                callback(&success);
                                            } else {
                                                success = false;
                                                callback(&success);
                                            }
                                        }];

}

-(BOOL)userAlreadyInTribe:(PFUser *)user {
    return ([self.members containsObject:user]) ? true : false;
}


#pragma mark - Loading users and activities

/**
 * Loads Tribe first and then get members of a tribe with their corresponding activity
 *
 */
-(void)loadTribeWithMembersAndActivitiesWithBlock:(void(^)(void))callback {
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self loadMembersOfTribeWithActivitiesWithBlock:^{
            callback();
        }];
    }];
}

/**
 * Loads members of a tribe with their corresponding activity
 *
 */
-(void)loadMembersOfTribeWithActivitiesWithBlock:(void(^)(void))callback {
    
    self.membersAndActivities = [[NSMutableArray alloc] init];
    
    // get array of members
    [self getMembersFromTribewithBlock:^(NSArray * tribeMembers) {
        
        // asign members property and use to later add to dictionary
        self.members = [NSMutableArray arrayWithArray:tribeMembers];
        
        // get activities for each member according to tribe passed
        [self getActivitiesOfMembers:self.members withBlock:^(NSArray * memberActivities) {
            
            self.activities = [NSMutableArray arrayWithArray:memberActivities];

            // iterate over both arrays (members and activity) to make a dictionary
            for (int i = 0; i < [self.members count]; i++ ) {
                
                PFUser * member = [self.members objectAtIndex:i];
                PFObject * activity = [self.activities objectAtIndex:i];

                NSDictionary * memberAndActivity = @{
                                                     @"member":member,
                                                     @"activity":activity,
                                                     };
                
                // add to 'master array'
                [self.membersAndActivities addObject:memberAndActivity];
                
                if (self.membersAndActivities.count == self.activities.count) {
                    callback();
                }
            }
            
        }];
        
    }];
}
-(void)getActivitiesOfMembers:(NSMutableArray *)tribeMembers withBlock:(void(^)(NSArray * activites))callback {
    
    NSMutableArray * memberActivities = [[NSMutableArray alloc] init];
    
    // get activity where createdBy = member and tribe.objID = tribe.objID
    for (PFUser * member in tribeMembers) {
        
        // get activity object by matching createdBy key to user and tribe key equals to corresponding tribe
        PFQuery * query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"createdBy" equalTo:member];
        [query whereKey:@"tribe" equalTo:self];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            if (!error) {
                [memberActivities addObject:object];
            } else {
                NSLog(@"error loading activity objects: %@", error);
            }
            
            // return activities when each member has an activity
            if (memberActivities.count == members.count) {
                callback(memberActivities);
            }
        }];
    }
}

-(void)getMembersFromTribewithBlock:(void(^)(NSArray * members))callback {
    
    // array to hold members
    NSMutableArray * membersPlaceholderArray = [[NSMutableArray alloc] init];

    // get relation of tribe object to the members
    PFRelation * membersOfTribeRelation = self[@"members"];

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
            NSLog(@"error loading member objects: %@", error);
        }
    }];
    
}

@end
