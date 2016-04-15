//
//  IAPHelper.h
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAPHelper : NSObject 

// states of subscription/user
-(int)daysRemainingOnSubscription;
-(NSDate *)expirationDate;
-(BOOL)userIsPremium;

// public methods to make purchase
-(void)make1MonthPremiumPurchase;
- (void)restore;

@end
