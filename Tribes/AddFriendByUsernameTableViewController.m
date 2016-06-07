//
//  AddFriendByUsernameTableViewController.m
//  Tribes
//
//  Created by German Espitia on 6/6/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddFriendByUsernameTableViewController.h"
#import <Parse/Parse.h>
#import "User.h"
#import "SCLAlertView.h"

@interface AddFriendByUsernameTableViewController () <UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation AddFriendByUsernameTableViewController

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
    PFQuery * query = [PFUser query];
    if ([_searchBar.text isEqualToString:@""]) {
        [query whereKey:@"NADA" equalTo:@YES];
        return query;
    } else {
        [query whereKey:@"name" containsString:_searchBar.text];
    }
    
    
    return query;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

-(PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    PFTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.text = [object objectForKey:@"name"];
    cell.detailTextLabel.text = @"Add";
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
    
    User * user = [self.objects objectAtIndex:indexPath.row];
    
    [_searchBar resignFirstResponder];
    
    // show alert to make sure user wants to add selected user to tribe
    SCLAlertView * confirmAlert = [[SCLAlertView alloc] initWithNewWindow];
    [confirmAlert addButton:@"YES" actionBlock:^{
        
        // make sure user is not already in tribe
        if (![user.tribes containsObject:_tribe]) {
            // if user confirm, add user to tribe
            [_tribe addUserToTribe:user withBlock:^(BOOL *success) {
                if (success) {
                    
                    [_tribe updateTribeWithBlock:^(bool success) {
                        if (success) {
                            SCLAlertView * successAlert = [[SCLAlertView alloc] initWithNewWindow];
                            [successAlert addButton:@"AWESOME" actionBlock:^{
                                [self.navigationController popToRootViewControllerAnimated:true];
                            }];
                            [successAlert showSuccess:@"Success 😄" subTitle:@"You've successfully added your buddy!" closeButtonTitle:nil duration:0.0];
                            
                            // send push to newly added member
                            NSString * message = [NSString stringWithFormat:@"%@ added you to %@!",[User currentUser][@"username"],_tribe[@"name"]];
                            [[User currentUser] sendPushFromMemberToMember:user withMessage:message habitName:@"" andCategory:@"RELOAD"];
                        }
                    }];
                
                } else {
                    SCLAlertView * errorAddingUserAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [errorAddingUserAlert showError:@"Oh oh.. 😬" subTitle:@"Looks like there was an error adding your friend to the Tribe. Sorry about that. Please try again." closeButtonTitle:@"GOT IT" duration:0.0];
                }
            }];
        }
        // user already in tribe, inform
        else {
            [confirmAlert hideView];
            SCLAlertView * alreadyInTribeAlert = [[SCLAlertView alloc] initWithNewWindow];
            [alreadyInTribeAlert addButton:@"GOT IT" actionBlock:^{
                [_searchBar becomeFirstResponder];
            }];
            [alreadyInTribeAlert showError:@"Already in Tribe 🙄" subTitle:@"Looks like your buddy is already in the Tribe." closeButtonTitle:nil duration:0.0];
        }
        

        
    }];
    
    NSString * message = [NSString stringWithFormat:@"Just to make sure you are adding the right member. Are you sure you want to add %@ to %@",user[@"username"],_tribe[@"name"]];
    [confirmAlert addButton:@"NEVER MIND" actionBlock:^{
        [_searchBar becomeFirstResponder];
    }];
    [confirmAlert showInfo:@"CONFIRM" subTitle:message closeButtonTitle:nil duration:0.0];
    

}

@end

