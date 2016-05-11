//
//  IAPHelper.h
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IAPHelper : NSObject 

// states of subscription/user
-(int)daysRemainingOnSubscription;
-(NSDate *)expirationDate;
-(BOOL)userIsPremium;

/**
 * UITableViewController to reloadDate when purchase completes.
 */
@property (nonatomic, strong) UITableViewController * tableViewControllerToConfigureAfterPurchase;
@property BOOL reload;
@property BOOL dismiss;

// public methods to make purchase
-(void)make1MonthPremiumPurchase;
-(void)make1MonthPremiumPurchaseWithTableViewController:(UITableViewController *)vc andReload:(BOOL)reload orDismiss:(BOOL)dismiss;
- (void)restore;

@end
