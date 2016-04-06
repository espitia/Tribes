//
//  IAPHelper.m
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "IAPHelper.h"

@implementation IAPHelper

/**
 * Returns int with days remaining on subscription.
 */
-(int)daysRemainingOnSubscription {
    NSDate *expirationDate = [[NSUserDefaults standardUserDefaults]
                              objectForKey:@"expirationDate"];
    
    NSTimeInterval timeInt = [expirationDate timeIntervalSinceDate:[NSDate date]];
    
    int days = timeInt / 60 / 60 / 24;

    if (days > 0) {
        return days;
    } else {
        return 0;
    }
    return 1;
}
-(NSDate *)expirationDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"expirationDate"];
}

/**
 * Returns BOOL indicating whether user is premium or not.
 */
-(BOOL)userIsPremium {
    return ([self daysRemainingOnSubscription] > 0);
}

/**
 * Adds 1 month to subscription whether user already has subscription or not.
 */
-(void)make1MonthPremiumPurchase {
    int daysLeft = [self daysRemainingOnSubscription];
    NSDate * newExpirationDate;
    
    // check if user already has subscription to add more time or set 1 month from now for new subscriber
    if (daysLeft > 0) {
        newExpirationDate = [[self expirationDate] dateByAddingTimeInterval:2592000];
    } else {
        newExpirationDate = [NSDate dateWithTimeIntervalSinceNow:2592000];
    }
    
    // save new expiration date
    [[NSUserDefaults standardUserDefaults] setObject:newExpirationDate forKey:@"expirationDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


@end

