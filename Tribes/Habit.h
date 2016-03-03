//
//  Habit.h
//  Tribes
//
//  Created by German Espitia on 3/2/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Habit : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

-(void)loadWithBlock:(void(^)(void))callback;

@property (nonatomic, strong) NSMutableArray * members;

@end

