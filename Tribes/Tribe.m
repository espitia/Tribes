//
//  TribeHandler.m
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Tribe.h"
#import <Parse/PFObject+Subclass.h>


@implementation Tribe {
    NSMutableArray * membersAndActivities;
}

+ (NSString *)parseClassName {
    return @"Tribe";
}

+ (void)load {
    [self registerSubclass];
}


/**
 * Load members of a tribe with their corresponding activity
 *
 * @param tribe from which you want to retrieve members and activities
 * @return A neat dictionary with 2 keys, "member" with a PFUser object and
 * "activity" with a PFObject of class type Activity
 */
-(NSMutableArray *)loadMembersOfTribeWithActivities {
    

    __block NSMutableArray * membersArray;
    __block NSMutableArray * activitiesArray;
    
    // get array of members
    [self getMembersFromTribewithBlock:^(NSArray *members) {
        
        // asign members to array to later add to dictionary
        membersArray = [NSMutableArray arrayWithArray:members];
        
        // get activities for each member according to tribe passed
        [self getActivitiesOfMembers:membersArray withBlock:^(NSArray * activities) {
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
-(void)getActivitiesOfMembers:(NSMutableArray *)members withBlock:(void(^)(NSArray * activites))callback {
    
    NSMutableArray * activities = [[NSMutableArray alloc] init];
    
    // get activity where createdBy = member and tribe.objID = tribe.objID
    for (PFUser * member in members) {
        
        // get activity object by matching createdBy key to user and tribe key equals to corresponding tribe
        PFQuery * query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"createdBy" equalTo:member];
        [query whereKey:@"tribe" equalTo:self];
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
            NSLog(@"error: %@", error);
        }
    }];
    
}

@end
