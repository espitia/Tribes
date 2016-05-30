//
//  Tribe.h
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parse.h"
#import "Habit.h"

@interface Tribe : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

//loading
-(void)loadTribeWithBlock:(void(^)(bool success))callback;

//updating
-(void)updateTribeWithBlock:(void(^)(bool success))callback;

// handling users
-(BOOL)membersAndActivitesAreLoaded;
-(BOOL)userAlreadyInTribe:(PFUser *)user;

// state of tirbe
-(BOOL)allHabitsAreCompleted;
-(id)userWithMostCompletionsForThisWeekOnNonWatcherHabits;
@property int lastWeeksCompletions;
@property int thisWeeksCompletions;

// adding to the tribe
-(void)addUserToTribe:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;
-(void)addHabitToTribeWithName:(NSString *)name andBlock:(void(^)(bool success))callback;

// on hold users
-(void)addUserToTribeOnHold:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;
-(void)confirmOnHoldUser:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;;
-(void)declineOnHoldUser:(PFUser *)user;


-(void)addTribeMembersToHabits:(NSArray *)membersArray;
-(void)addTribeMembersToTribe:(NSArray *)membersArray;


@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSMutableArray * membersAndActivities;
@property (nonatomic, strong) NSMutableArray * tribeMembers;
@property (nonatomic, strong) NSMutableArray * onHoldMembers;
@property (nonatomic, strong) NSMutableArray * habits;
@property (nonatomic, strong) NSMutableArray * nonWatcherHabits;
@property BOOL privacy;



@end
