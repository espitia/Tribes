//
//  AddTribeTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/10/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddTribeTableViewController.h"
#import "Parse.h"

@interface AddTribeTableViewController () {
    PFUser * currentUser;
    UITextField * tribeNameTextField;
}

@end

@implementation AddTribeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to create Tribe
    UIBarButtonItem * createTribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createTribe)];
    [self.navigationItem setRightBarButtonItem:createTribeButton];
    
    // set current user
    currentUser = [PFUser currentUser];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    // set keyboard to appear
    [tribeNameTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // different number of rows depending on if the user wants to create/join a tribe
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 2;
            break;
            
        default:
            return 1;
            break;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return @"Create your own Tribe:";
            break;
        case 1:
            return @"Join an already existing Tribe:";
            break;
        default:
            return @"Join a Tribe";
            break;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeCell" forIndexPath:indexPath];
    
    // Cell to create Tribe
    CGRect activityNameFrame = CGRectMake(15,
                                          cell.frame.origin.y - 30,
                                          cell.frame.size.width,
                                          cell.frame.size.height);
    tribeNameTextField = [[UITextField alloc] initWithFrame:activityNameFrame];
    [tribeNameTextField setFont:[UIFont systemFontOfSize:40]];
    [cell.contentView addSubview:tribeNameTextField];
    
    // Cells to join a Tribe
    
    return cell;
}

#pragma mark - Stuff

-(void)createTribe {
    
    // create a tribe
    NSLog(@"%@", tribeNameTextField);
    PFObject * tribe = [PFObject objectWithClassName:@"Tribe"];
    NSLog(@"tribename: %@", [tribeNameTextField text]);
    NSString * xxx = tribeNameTextField.text;
    NSLog(@"testing: %@", xxx);
    [tribe setObject:tribeNameTextField.text forKey:@"name"];
    
    // add user to tribe relation
    PFRelation * tribeRelationToUsers = [tribe relationForKey:@"users"];
    [tribeRelationToUsers addObject:currentUser];
    
    // add tribe to user array
    [currentUser addObject:tribe forKey:@"tribes"];
    
    // create activity
    PFObject * activity = [PFObject objectWithClassName:@"Activity"];

    // add user to activity
    [activity setObject:currentUser forKey:@"createdBy"];

    // add activity to user
    [currentUser addObject:activity forKey:@"activities"];
    
    // set tribe in activity
    [activity setObject:tribe forKey:@"tribe"];
    
    // save tribe
    [tribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        // save activity [MUST BE SAVED AFTER TRIBE IS COMPLETED, ELSE -> ERROR (pfrelation)]
        [activity saveInBackground];
    }];
    
    // save user
    [currentUser saveInBackground];

    // pop to root
    [self.navigationController popToRootViewControllerAnimated:true];
}


@end
