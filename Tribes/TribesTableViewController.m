//
//  TribesTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribesTableViewController.h"
#import "Parse.h"
#import "SignupViewController.h"
#import "TribeDetailTableViewController.h"

@interface TribesTableViewController () {
    PFUser * currentUser;
}

@end

@implementation TribesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set currentUser
    currentUser = [PFUser currentUser];
    
    //  log in / sign up user if non-existent
    if (!currentUser) {
        [self signUp];
    } else {
        // load tribes
        [self loadTribes];
    }

    // init instance/public variables needed
    _tribes = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tribes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeCell" forIndexPath:indexPath];
    
    PFObject * tribe = _tribes[indexPath.row];
    cell.textLabel.text = tribe[@"name"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject * tribeTapped = [_tribes objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"TribeDetail" sender:tribeTapped];
}

#pragma mark - User login/signup

-(void)signUp {

//    [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    SignupViewController * signupVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Signup"];
    [self.navigationController presentViewController:signupVC animated:false completion:nil];
}

#pragma mark - Segue handling

-(IBAction)unwindFromAddTribe:(UIStoryboardSegue *)segue {
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // show tribe
    if ([segue.identifier isEqualToString:@"TribeDetail"]) {
        
        // initiate tribedetailvc
        TribeDetailTableViewController * tribeDetailVC = (TribeDetailTableViewController *)segue.destinationViewController;
        // sender contains tribe tapped
        tribeDetailVC.tribe = sender;
    }
}

#pragma mark - Helper methods

-(void)loadTribes {
    
    // get user
    PFQuery *userQuery = [PFUser query];
    
    // include tribe objects
    [userQuery includeKey:@"tribes"];
    
    // fetch user
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray * objects, NSError *error) {
        
        // stick tribe objects in local tribes instance variable
        PFUser * user = objects[0];
        NSLog(@"%@", _tribes);
        [_tribes addObjectsFromArray:user[@"tribes"]];
        NSLog(@"%@", _tribes);

        [self.tableView reloadData];
    }];
}
@end
