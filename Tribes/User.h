//
//  User.h
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Tribe.h"
#import "Activity.h"

@interface User : PFUser <PFSubclassing>

+(void)load;

-(void)loadTribesWithBlock:(void(^)(void))callback;
-(void)completeActivityForTribe:(Tribe *)tribe;
-(Activity *)activityForTribe:(Tribe *)tribe;
-(void)addTribeWithName:(NSString *)name;
-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe withBlock:(void (^)(BOOL))callback;
-(void)sendPushToMember:(User *)member withMessage:(NSString *)msg withBlock:(void (^)(BOOL * success))callback;

@property (nonatomic, strong) NSMutableArray * tribes;
@property (nonatomic, strong) NSArray * activities;
@property BOOL loadedInitialTribes;

@end
