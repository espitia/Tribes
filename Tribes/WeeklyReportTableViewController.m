//
//  WeeklyReportTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/28/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "WeeklyReportTableViewController.h"
#import "RecognitionTableViewCell.h"
#import "HabitReportTableViewCell.h"

@interface WeeklyReportTableViewController ()

@end

@implementation WeeklyReportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Weekly Report 📈";
    
    // register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"RecognitionTableViewCell"
                                               bundle:nil]
         forCellReuseIdentifier:@"RecognitionCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"HabitReportTableViewCell"
                                               bundle:nil]
         forCellReuseIdentifier:@"HabitCell"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // on recognition section, show one row
    if (section == 0) {
        return 1;
    }
    // on habit report sections, show a row for each member + a row for the labels
    else {
        return _tribe.tribeMembers.count + 1;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return @"Recognitions:";
            break;
        case 1:
            return @"Individuals:";
            break;
            
        default:
            break;
    }
    return @"";
    
}
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//
//}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        RecognitionTableViewCell * cell = [[RecognitionTableViewCell alloc] init];
        cell = [tableView dequeueReusableCellWithIdentifier:@"RecognitionCell" forIndexPath:indexPath];
        [self configureCellForRecognitionCell:cell];
    }
    
    
    else {
        HabitReportTableViewCell * cell = [[HabitReportTableViewCell alloc] init];
        cell = [tableView dequeueReusableCellWithIdentifier:@"HabitCell" forIndexPath:indexPath];
        [self configureCellForHabitCell:cell andIndexPath:indexPath];
    }

    return cell;
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
