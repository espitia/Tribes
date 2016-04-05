//
//  IAPHelper.m
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "IAPHelper.h"

@implementation IAPHelper

-(int)daysRemainingOnSubscription {
    NSDate *expirationDate = [[NSUserDefaults standardUserDefaults]
                              objectForKey:@"expirationDate"];
    
    NSTimeInterval timeInt = [expirationDate timeIntervalSinceDate:[NSDate date]];
    
    //3
    int days = timeInt / 60 / 60 / 24;
    
    //4
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
@end

