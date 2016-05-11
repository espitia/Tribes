//
//  AddMemberOrHabitMenuTableViewController.m
//  Tribes
//
//  Created by German Espitia on 4/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddMemberOrHabitMenuTableViewController.h"
#import "User.h"
#import "Tribe.h"
#import "HabitsTableViewController.h"
#import "MembersTableViewController.h"

@interface AddMemberOrHabitMenuTableViewController ()

@end

@implementation AddMemberOrHabitMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return (self.addMember) ? @"Tribe to add member to:" :
                            @"Tribe to habit to:";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [User currentUser].tribes.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID" forIndexPath:indexPath];
    
    Tribe * tribe = [[User currentUser].tribes objectAtIndex:indexPath.row];
    cell.textLabel.text = tribe.name;
    // Configure the cell...
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"add member? : %d", self.addMember);
    Tribe * tribe = [[User currentUser].tribes objectAtIndex:indexPath.row];
    if (self.addMember) {
        [self performSegueWithIdentifier:@"AddMember" sender:tribe];
    } else {
        [self performSegueWithIdentifier:@"AddHabit" sender:tribe];

    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddHabit"]) {
        Tribe * tribe = sender;
        HabitsTableViewController * habitsVC = (HabitsTableViewController *)segue.destinationViewController;
        habitsVC.tribe = tribe;
    } else if ([segue.identifier isEqualToString:@"AddMember"]) {
        Tribe * tribe = sender;
        MembersTableViewController * membersVC = (MembersTableViewController *)segue.destinationViewController;
        membersVC.tribe = tribe;
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
