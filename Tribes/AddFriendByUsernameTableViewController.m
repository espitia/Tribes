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
    

    
}

@end

