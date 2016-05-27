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
        return query;
    } else {
        [query whereKey:@"name" containsString:_searchBar.text];
        [query includeKey:@"admin"];
    }
    
    return query;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

-(PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    PFTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    cell.textLabel.text = [object objectForKey:@"name"];
    
    return cell;
}
#pragma mark - Search bar delegate

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    [self loadObjects];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", self.objects);
}

@end
