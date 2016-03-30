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


-(void)configureCellForRecognitionCell:(RecognitionTableViewCell *)cell {
    
    User * user = [_tribe userWithMostCompletionsForLastWeek];
    cell.recognitionTitle.text = @"Most completions:";
    int lastWeeksCompletions = [user lastWeekCompletionsForTribe:_tribe];
    cell.member.text = [NSString stringWithFormat:@"%@: %d completions!", user[@"name"], lastWeeksCompletions];
    cell.emojiReward.text = @"🏅";
}

-(void)configureCellForHabitCell:(HabitReportTableViewCell *)cell andIndexPath:(NSIndexPath *)indexPath {

    // labels cell
    if (indexPath.row == 0) {
        cell.username.text = @"";
        cell.thisWeekCompletionsleftView.image = nil;
        cell.changeLeftView.image = nil;
        
        cell.lastWeekCompletions.lineBreakMode = NSLineBreakByWordWrapping;
        cell.lastWeekCompletions.textAlignment = NSTextAlignmentCenter;
        cell.lastWeekCompletions.numberOfLines = 2;
        [cell.lastWeekCompletions setFont:[UIFont boldSystemFontOfSize:10]];
        
        cell.thisWeekCompletions.lineBreakMode = NSLineBreakByWordWrapping;
        cell.thisWeekCompletions.textAlignment = NSTextAlignmentCenter;
        cell.thisWeekCompletions.numberOfLines = 2;
        [cell.thisWeekCompletions setFont:[UIFont boldSystemFontOfSize:10]];
        
        cell.changeOverWeek.lineBreakMode = NSLineBreakByWordWrapping;
        cell.changeOverWeek.textAlignment = NSTextAlignmentCenter;
        cell.changeOverWeek.numberOfLines = 2;
        [cell.changeOverWeek setFont:[UIFont boldSystemFontOfSize:10]];
        
        cell.lastWeekCompletions.text = @"Last week";
        cell.thisWeekCompletions.text = @"This week";
        cell.changeOverWeek.text = @"Change";
    }
    
    else {
        User * user = [_tribe.tribeMembers objectAtIndex:indexPath.row - 1];
        // set name
        cell.username.text = user[@"name"];
        
        int lastWeekCompletions = [user lastWeekCompletionsForTribe:_tribe];
        int thisWeeksCompletions = [user thisWeekCompletionsForTribe:_tribe];
        int changeOverWeek = lastWeekCompletions - thisWeeksCompletions;
        
        NSString * thisWeek;
        if (thisWeeksCompletions > lastWeekCompletions) {
            cell.thisWeekCompletionsleftView.image = [UIImage imageNamed:@"green-up-arrow"];
            thisWeek = [NSString stringWithFormat:@"%d", thisWeeksCompletions];
        } else if (thisWeeksCompletions < lastWeekCompletions) {
            cell.thisWeekCompletionsleftView.image = [UIImage imageNamed:@"red-down-arrow"];
            thisWeek = [NSString stringWithFormat:@"%d", thisWeeksCompletions];
        } else {
            thisWeek = [NSString stringWithFormat:@"%d", thisWeeksCompletions];
        }
        NSString * lastWeek = [NSString stringWithFormat:@"%d", lastWeekCompletions];
        NSString * change = [NSString stringWithFormat:@"%d", changeOverWeek];

        cell.lastWeekCompletions.text = lastWeek;
        cell.thisWeekCompletions.text = thisWeek;
        cell.changeOverWeek.text = change;
    }

    
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // on recognition section, show one row
    if (indexPath.section == 0) {
        return 100;
    }
    // on habit report sections, show a row for each member
    else {
        return 50;
    }
  
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

#pragma mark - Helper methods
- (NSString *)imageToNSString:(UIImage *)image
{
    NSData *imageData = UIImagePNGRepresentation(image);
    
    return [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (UIImage *)stringToUIImage:(NSString *)string
{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:string
                                                      options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return [UIImage imageWithData:data];
}

@end
