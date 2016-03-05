//
//  Tribe.h
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parse.h"

@interface Tribe : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

//loading
-(void)loadTribeWithMembersAndHabitsWithBlock:(void(^)(void))callback;
-(void)updateMembersWithBlock:(void(^)(void))callback;
-(void)updateMemberActivitiesWithBlock:(void(^)(void))callback;

// handling users
-(BOOL)membersAndActivitesAreLoaded;
-(BOOL)allMembersCompletedActivity;
-(BOOL)userAlreadyInTribe:(PFUser *)user;
-(void)addUserToTribe:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;

//sorting
-(void)sortMembersAndActivitiesByTotalActivityCompletions;
-(void)sortMembersAndActivitiesByWeeklyActivityCompletions;

//push
-(void)sendTribe100PercentCompletedPush;

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSMutableArray * membersAndActivities;
@property (nonatomic, strong) NSMutableArray * tribeMembers;
@property (nonatomic, strong) NSMutableArray * habits;



@end
