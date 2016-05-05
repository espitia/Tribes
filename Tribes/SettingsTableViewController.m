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
#import "Helpshift.h"

@interface SettingsTableViewController () {
    IAPHelper * iAPHelper;
}

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
    iAPHelper = [[IAPHelper alloc] init];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"General";
            break;
        case 1:
            sectionName = @"Let's connect 🤗";
            break;
            // ...
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    if ([iAPHelper userIsPremium]) {
                        title = [NSString stringWithFormat:@"Subscribed!🏅Expires in %d days", [iAPHelper daysRemainingOnSubscription]];
                    } else {
                        title = @"Upgrade ⭐️";
                    }
                }
                    break;
                case 1: {
                    if ([iAPHelper userIsPremium]) {
                        title = @"Extend your subscription ⭐";
                    } else {
                        title = @"Remove Ads 🚫";
                    }

                }
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    title = @"Live chat 💬";
                    break;
                case 1:
                    title = @"Snapchat 👻";
                    break;
                    
                default:
                    break;
            }
            
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
                    // if premium, ask to extend, if not, show premium vc
                    if ([iAPHelper userIsPremium]) {
                        [self extendPremiumOptions];
                    } else {
                        PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumWeeklyReport];
                        [self presentViewController:premiumVC animated:true completion:nil];
                    }
                }
                    break;
                case 1: {
                    // if premium, ask to extend, if not, show premium vc
                    if ([iAPHelper userIsPremium]) {
                        [self extendPremiumOptions];
                    } else {
                        PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumRemoveAds];
                        [self presentViewController:premiumVC animated:true completion:nil];
                    }

                }
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    [[Helpshift sharedInstance] showConversation:self
                                                     withOptions:nil];
                }
                    break;
                case 1:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.snapchat.com/add/tribeshq"]];
                    
                default:
                    break;
            }
            
        default:
            break;
    }
}

-(void)extendPremiumOptions {
    SCLAlertView * extendPremium = [[SCLAlertView alloc] initWithNewWindow];
    [extendPremium addButton:@"ADD 1 MONTH" actionBlock:^{
        [iAPHelper make1MonthPremiumPurchaseWithTableViewController:self andReload:true orDismiss:false];
    }];
    [extendPremium showSuccess:@"Extend Subscription" subTitle:@"You already have Tribes Premium. Would you like to extend your subscription?" closeButtonTitle:@"MAYBE LATER" duration:0.0];
    
}
@end
