//
//  SettingsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/17/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Parse.h"
#import "SCLAlertView.h"
#import "IAPHelper.h"
#import "PremiumViewController.h"
#import "SCLAlertView.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    IAPHelper * helper = [[IAPHelper alloc] init];
    return ([helper userIsPremium]) ? 1 : 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    IAPHelper * helper = [[IAPHelper alloc] init];
                    if ([helper userIsPremium]) {
                        title = [NSString stringWithFormat:@"Subscribed!🏅Expires in %d days", [helper daysRemainingOnSubscription]];
                    } else {
                        title = @"Upgrade ⭐️";
                    }
                }
                    break;
                case 1: {
                    title = @"Remove Ads 🚫";
                }
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    cell.textLabel.text = title;

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //deselect row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    IAPHelper * helper = [[IAPHelper alloc] init];
                    if ([helper userIsPremium]) {
                        [self extendPremiumOptions];
                    } else {
                        PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumWeeklyReport];
                        [self presentViewController:premiumVC animated:true completion:nil];
                    }
                }
                    break;
                case 1: {
                    PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumRemoveAds];
                    [self presentViewController:premiumVC animated:true completion:nil];

                }
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

-(void)extendPremiumOptions {
    SCLAlertView * extendPremium = [[SCLAlertView alloc] initWithNewWindow];
    [extendPremium addButton:@"Add 1 Month" actionBlock:^{
        IAPHelper * helper = [[IAPHelper alloc] init];
        [helper make1MonthPremiumPurchase];
    }];
    
}
@end
