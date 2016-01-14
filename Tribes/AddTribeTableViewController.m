//
//  AddTribeTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/10/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribesTableViewController.h"
#import "AddTribeTableViewController.h"
#import "Parse.h"
#import "Tribe.h"

@interface AddTribeTableViewController () {
    PFUser * currentUser;
    UITextField * tribeNameTextField;
    Tribe * tribe;
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

    // initialize textfield
    tribeNameTextField = [[UITextField alloc] init];
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
    
    // cell for creating a new tribe (first section and row)
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        // add uitextfield for name fo tribe
        CGRect activityNameFrame = CGRectMake(15,
                                              cell.frame.origin.y - 30,
                                              cell.frame.size.width,
                                              cell.frame.size.height);
        [tribeNameTextField setFrame:activityNameFrame];
        tribeNameTextField.placeholder = @"e.g. Reading";
        [tribeNameTextField setFont:[UIFont systemFontOfSize:40]];
        [cell.contentView addSubview:tribeNameTextField];
    }
    


    // Cells to join a Tribe
    // XXXXXXX TO DO XXXXXXX
    
    return cell;
}

#pragma mark - Stuff

-(void)createTribe {
    
    // create a tribe
    tribe = [Tribe object];
    
    // set name key
    [tribe setObject:tribeNameTextField.text forKey:@"name"];
    
    // add user to tribe relation
    PFRelation * tribeRelationToUsers = [tribe relationForKey:@"members"];
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

        // save user
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            // send tribe back to main viewcontroller after neccessary saves (tribe and user objects)
            [self performSegueWithIdentifier:@"unwindFromAddTribe" sender:self];

            // save activity
            [activity saveInBackground];
        }];
    }];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // send back tribe object to mainVC
    if ([segue.identifier  isEqual: @"unwindFromAddTribe"]) {
        TribesTableViewController * vc = (TribesTableViewController *)segue.destinationViewController;
        [vc.tribes addObject:tribe];
        [vc.tableView reloadData];
    }
}

@end
