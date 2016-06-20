//
//  FindTribesViewController.m
//  Tribes
//
//  Created by German Espitia on 5/27/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "FindTribesViewController.h"
#import <Parse/Parse.h>
#import "User.h"
#import "SCLAlertView.h"

@interface FindTribesViewController () <UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation FindTribesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _searchBar.delegate = self;
    self.pullToRefreshEnabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated {
    [_searchBar becomeFirstResponder];
}

#pragma mark - Data source


-(PFQuery *)queryForTable {
    PFQuery * query = [PFQuery queryWithClassName:@"Tribe"];

    if ([_searchBar.text isEqualToString:@""]) {
        [query whereKey:@"prime" equalTo:@YES];
        [query includeKey:@"admin"];
        return query;
    } else {
        [query whereKey:@"nameLowerCase" containsString:[_searchBar.text lowercaseString]];
        [query includeKey:@"admin"];
    }
    
    return query;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

-(PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    PFTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    NSString * title;
    
    if ([object objectForKey:@"admin"]) {
        title = [NSString stringWithFormat:@"%@ by %@", [object objectForKey:@"name"],[object objectForKey:@"admin"][@"username"]];
    } else {
        title =  [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
    }
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = @"Join";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}
#pragma mark - Search bar delegate

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    [self loadObjects];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    [_searchBar resignFirstResponder];
    
    // get tribe
    Tribe * tribe = [self.objects objectAtIndex:indexPath.row];
    
    // ask user to confirm joining tribe
    NSString * tribeNameAndAdmin = [NSString stringWithFormat:@"%@ by %@", tribe[@"name"], tribe[@"admin"][@"username"]];
    NSString * alertMessage = [NSString stringWithFormat:@"Just to make sure you are joining the right Tribe. Are you sure you want to join %@?", tribeNameAndAdmin];
    
    // show alert
    SCLAlertView * confirmAlert = [[SCLAlertView alloc] initWithNewWindow];
    [confirmAlert addButton:@"YES" actionBlock:^{
        
        // add to tribe
        [self addToTribe:tribe];
        
    }];
    [confirmAlert addButton:@"NEVER MIND" actionBlock:^{
        // show keyboard again
        [_searchBar becomeFirstResponder];
    }];
    [confirmAlert showInfo:@"Confirm" subTitle:alertMessage  closeButtonTitle:nil duration:0.0];
    
}

-(void)addToTribe:(Tribe *)tribe {
    
    if (tribe.privacy) {
        // add to private tribe
        [tribe addUserToTribeOnHold:[User currentUser] withBlock:^(BOOL *success) {
            if (success) {
                // pop to root view controller
                SCLAlertView * successAlert  = [[SCLAlertView alloc] initWithNewWindow];
                NSString * alertMessage = [NSString stringWithFormat:@"You've successfully been added to %@. Since this is a private Tribe, the admin has been notified to confirm. To make the process quicker, tell him to check the Tribe NOW!",tribe[@"name"]];
                [successAlert addButton:@"AWESOME" actionBlock:^{
                    [self.navigationController popToRootViewControllerAnimated:true];
                }];
                [successAlert showSuccess:@"Success 😃" subTitle:alertMessage closeButtonTitle:nil duration:0.0];
            } else {
                // show error, try again :(
                SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
                [errorAlert showError:@"Oh oh... 😬" subTitle:@"There was an error while adding you to the Tribe. We're sorry. This shouldn't happen. Please check that your internet connection is working and try again." closeButtonTitle:@"GOT IT" duration:0.0];
            }
        }];
        
        
        
    } else {
        // add to public tribe
        [tribe addUserToTribe:[User currentUser] withBlock:^(BOOL *success) {
            
            if (success) {
                // pop to root view controller
                SCLAlertView * successAlert  = [[SCLAlertView alloc] initWithNewWindow];
                NSString * alertMessage = [NSString stringWithFormat:@"You've successfully been added to %@. Good luck!",tribe[@"name"]];
                [successAlert addButton:@"AWESOME" actionBlock:^{
                    [[User currentUser] fetchUserFromNetworkWithBlock:^(bool success) {
                        if (success) {
                            [self.navigationController popToRootViewControllerAnimated:true];
                        }
                    }];
                }];
                [successAlert showSuccess:@"Success 😃" subTitle:alertMessage closeButtonTitle:nil duration:0.0];
            } else {
                // show error, try again :(
                SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
                [errorAlert showError:@"Oh oh... 😬" subTitle:@"There was an error while adding you to the Tribe. We're sorry. This shouldn't happen. Please check that your internet connection is working and try again." closeButtonTitle:@"GOT IT" duration:0.0];
            }
            
            
        }];
    }
}


@end
