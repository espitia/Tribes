//
//  JoinTribeManagerTableViewController.m
//  Tribes
//
//  Created by German Espitia on 5/27/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "JoinTribeManagerTableViewController.h"

@interface JoinTribeManagerTableViewController ()

@end

@implementation JoinTribeManagerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Join a Tribe";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
            
        default:
            break;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    NSString * title = @"";
    NSString * detail = @"";
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    title = @"Create a Tribe 🏆";
                    detail = @"Start a dynasty";
                    break;
                case 1:
                    title = @"Join a Tribe 👫";
                    detail = @"Become part of the squad";
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:false];

    switch (indexPath.row) {
        case 0:
            [self performSegueWithIdentifier:@"createTribe" sender:nil];
            break;
        case 1:
            [self performSegueWithIdentifier:@"JoinATribe" sender:nil];
            break;
            
        default:
            break;
    }
}


@end
