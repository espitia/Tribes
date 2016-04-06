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
-(void)make1MonthPremiumPurchaseWithNewExpirationDate:(NSDate *)newExpirationDate {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"premium"];
    [[NSUserDefaults standardUserDefaults] setObject:newExpirationDate forKey:@"expirationDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

