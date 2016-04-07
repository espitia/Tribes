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

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    title = @"Remove Ads 🚫";
                    break;
                case 1: {
                    IAPHelper * helper = [[IAPHelper alloc] init];
                    if ([helper userIsPremium]) {
                        title = [NSString stringWithFormat:@"Subscribed!🏅Expires in %d days", [helper daysRemainingOnSubscription]];
                    } else {
                        title = @"Upgrade ⭐️";
                    }
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
                    PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumRemoveAds];
                    [self presentViewController:premiumVC animated:true completion:nil];
                }
                    break;
                case 1: {
                    IAPHelper * helper = [[IAPHelper alloc] init];
                    if ([helper userIsPremium]) {
                        
                    } else {
                        PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumWeeklyReport];
                        [self presentViewController:premiumVC animated:true completion:nil];
                    }
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

@end
