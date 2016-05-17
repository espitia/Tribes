//
//  PremiumChildViewController.m
//  Tribes
//
//  Created by German Espitia on 4/6/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "PremiumChildViewController.h"
#import "IAPHelper.h"
#import "SCLAlertView.h"

@implementation PremiumChildViewController {
    NSArray * images;
    IBOutlet UIButton *upgradeButton;
    IAPHelper * iAPHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   
    iAPHelper = [[IAPHelper alloc] init];
    
    
    [[upgradeButton layer] setBorderWidth:1.0f];
    [[upgradeButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    [upgradeButton setTitleEdgeInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0,5.0)];

    upgradeButton.layer.cornerRadius = 10; // this value vary as per your desire
    upgradeButton.clipsToBounds = YES;
}

- (IBAction)upgrade:(id)sender {

    
    SCLAlertView * buyPremium = [[SCLAlertView alloc] initWithNewWindow];
    [buyPremium addButton:@"Add 1 month for $1.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:1 WithTableViewController:self andReload:false orDismiss:false];
    }];
    [buyPremium addButton:@"Add 3 months for $5.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:3 WithTableViewController:self andReload:false orDismiss:false];
    }];
    [buyPremium addButton:@"Add 6 months for $9.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:6 WithTableViewController:self andReload:false orDismiss:false];
    }];
    [buyPremium showSuccess:@"Upgrade" subTitle:@"Upgrade to Tribes Premium to get access to weekly reports." closeButtonTitle:@"Maybe later" duration:0.0];

}
- (IBAction)restore:(id)sender {
    [iAPHelper restore];
}
- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}



@end
