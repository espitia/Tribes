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

-(BOOL)completedForDay;

@property (nonatomic, strong) NSMutableArray * completionDates;
@property (nonatomic, strong) NSNumber * completionProgress;

@end

