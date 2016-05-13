//
//  PremiumChildViewController.m
//  Tribes
//
//  Created by German Espitia on 4/6/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "PremiumChildViewController.h"
#import "IAPHelper.h"


@implementation PremiumChildViewController {
    NSArray * images;
    IBOutlet UIButton *upgradeButton;
    IAPHelper * iAPHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   
    iAPHelper = [[IAPHelper alloc] init];
}

- (IBAction)upgrade:(id)sender {
    [iAPHelper make1MonthPremiumPurchaseWithTableViewController:self andReload:false orDismiss:true];
}
- (IBAction)restore:(id)sender {
    [iAPHelper restore];
}
- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}



@end
