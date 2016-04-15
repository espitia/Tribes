//
//  IAPHelper.m
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>
#import <QuartzCore/QuartzCore.h>


@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end

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
-(void)add1MonthToSubscription {
    int daysLeft = [self daysRemainingOnSubscription];
    NSDate * newExpirationDate;
    
    // check if user already has subscription to add more time or set 1 month from now for new subscriber
    if (daysLeft > 0) {
        newExpirationDate = [[self expirationDate] dateByAddingTimeInterval:2678400];
    } else {
        newExpirationDate = [NSDate dateWithTimeIntervalSinceNow:2678400];
    }
    
    // save new expiration date
    [[NSUserDefaults standardUserDefaults] setObject:newExpirationDate forKey:@"expirationDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.tableViewControllerToConfigureAfterPurchase && self.reload) {
        [self.tableViewControllerToConfigureAfterPurchase.tableView reloadData];
    } else if (self.tableViewControllerToConfigureAfterPurchase && self.dismiss) {
        [self.tableViewControllerToConfigureAfterPurchase dismissViewControllerAnimated:true completion:nil];
    }
    
}

#pragma mark - Purchasing Premium
#define kBecomePremiumProductIdentifier @"com.tribes.1monthsub"
/**
 * Pass UITableViewController to reload data when purchaes is complete.
 */
-(void)make1MonthPremiumPurchaseWithTableViewController:(UITableViewController *)vc andReload:(BOOL)reload orDismiss:(BOOL)dismiss {
    self.tableViewControllerToConfigureAfterPurchase = vc;
    self.reload = reload;
    self.dismiss = dismiss;
    [self make1MonthPremiumPurchase];
}
-(void)make1MonthPremiumPurchase {
    
    
    NSLog(@"User requests to come premium");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        
        //If you have more than one in-app purchase, and would like
        //to have the user purchase a different product, simply define
        //another function and replace kRemoveAdsProductIdentifier with
        //the identifier for the other product
        
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kBecomePremiumProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        
    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        //this is called the user cannot make payments, most likely due to parental controls
    }
}
- (void)restore {
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        [self purchase:validProduct];
    }
    else if(!validProduct){
        NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (void)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state -> Restored");
            
            [self add1MonthToSubscription];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [self add1MonthToSubscription]; //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}



@end
