//
//  IAPHelper.h
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAPHelper : NSObject
-(int)daysRemainingOnSubscription;
-(NSDate *)expirationDate;
-(BOOL)userIsPremium;
-(void)make1MonthPremiumPurchase;

@end
