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
#import "TribeReportTableViewCell.h"

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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TribeReportTableViewCell"
                                               bundle:nil]
         forCellReuseIdentifier:@"TribeReportCell"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0: // recognitions section
            return 1;
            break;
        case 1: // tribe report section
            return 1;
            break;
        case 2: // individuals section
            return _tribe.tribeMembers.count + 1;
            break;
        default:
            return 1;
            break;
    }

}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return @"Recognitions:";
            break;
        case 1:
            return @"Tribe:";
            break;
        case 2:
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
    
    // recognition cells
    if (indexPath.section == 0) {
        RecognitionTableViewCell * cell = [[RecognitionTableViewCell alloc] init];
        cell = [tableView dequeueReusableCellWithIdentifier:@"RecognitionCell" forIndexPath:indexPath];
        [self configureCellForRecognitionCell:cell];
    }
    
    // tribe report cell
    else if (indexPath.section == 1) {
        TribeReportTableViewCell * cell = [[TribeReportTableViewCell alloc] init];
        cell = [tableView dequeueReusableCellWithIdentifier:@"TribeReportCell" forIndexPath:indexPath];
        [self configureCellForTribeReportCell:cell];
    }
    
    // habit report cells
    else if (indexPath.section == 2) {
        HabitReportTableViewCell * cell = [[HabitReportTableViewCell alloc] init];
        cell = [tableView dequeueReusableCellWithIdentifier:@"HabitCell" forIndexPath:indexPath];
        [self configureCellForHabitCell:cell andIndexPath:indexPath];
    }
    
    cell.userInteractionEnabled = false;

    return cell;

}


-(void)configureCellForRecognitionCell:(RecognitionTableViewCell *)cell {
    
    User * user = [_tribe userWithMostCompletionsForThisWeekOnNonWatcherHabits];
    cell.recognitionTitle.text = @"Most completions:";
    int thisWeeksCompletions = [user thisWeekCompletionsForNonWatcherHabitsForTribe:_tribe];
    cell.member.text = [NSString stringWithFormat:@"%@: %d completions!", user[@"username"], thisWeeksCompletions];
    cell.emojiReward.text = @"🏅";
}

-(void)configureCellForTribeReportCell:(TribeReportTableViewCell *)cell {
    
    NSString * thisWeeksCompletions = [NSString stringWithFormat:@"%d", _tribe.thisWeeksCompletions];
    NSString * lastWeeksCompletions = [NSString stringWithFormat:@"%d", _tribe.lastWeeksCompletions];
    NSString * growth = [NSString stringWithFormat:@"%d", _tribe.thisWeeksCompletions - _tribe.lastWeeksCompletions];
    
    if (_tribe.thisWeeksCompletions > _tribe.lastWeeksCompletions) {
        cell.thisWeeksCompletionsLeftView.image = [UIImage imageNamed:@"green-up-arrow"];
        cell.growthLeftView.image = [UIImage imageNamed:@"green-up-arrow"];
    } else if(_tribe.thisWeeksCompletions < _tribe.lastWeeksCompletions) {
        cell.thisWeeksCompletionsLeftView.image = [UIImage imageNamed:@"red-down-arrow"];
        cell.growthLeftView.image = [UIImage imageNamed:@"red-down-arrow"];
    } else {
        cell.thisWeeksCompletionsLeftView.image = nil;
        cell.growthLeftView.image = nil;
    }
    
    cell.thisWeeksCompletions.text = thisWeeksCompletions;
    cell.lastWeeksCompletions.text = lastWeeksCompletions;
    cell.growth.text = growth;
    
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
        cell.changeOverWeek.text = @"Growth";
    }
    
    else { // individuals' cells
        
        User * user = [_tribe.tribeMembers objectAtIndex:indexPath.row - 1];
        // set name
        cell.username.text = user[@"username"];
        
        int lastWeekCompletions = [user lastWeekCompletionsForTribe:_tribe];
        int thisWeeksCompletions = [user thisWeekCompletionsForTribe:_tribe];
        int changeOverWeek = thisWeeksCompletions - lastWeekCompletions;
        

        if (thisWeeksCompletions > lastWeekCompletions) {
            cell.thisWeekCompletionsleftView.image = [UIImage imageNamed:@"green-up-arrow"];
            cell.changeLeftView.image = [UIImage imageNamed:@"green-up-arrow"];
        } else if (thisWeeksCompletions < lastWeekCompletions) {
            cell.thisWeekCompletionsleftView.image = [UIImage imageNamed:@"red-down-arrow"];
            cell.changeLeftView.image = [UIImage imageNamed:@"red-down-arrow"];
        } else {
            cell.thisWeekCompletionsleftView.image = nil;
            cell.changeLeftView.image = nil;
        }
        NSString * lastWeek = [NSString stringWithFormat:@"%d", lastWeekCompletions];
        NSString * thisWeek = [NSString stringWithFormat:@"%d", thisWeeksCompletions];
        NSString * change = [NSString stringWithFormat:@"%d", changeOverWeek];

        cell.lastWeekCompletions.text = lastWeek;
        cell.thisWeekCompletions.text = thisWeek;
        cell.changeOverWeek.text = change;
    }

    
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    switch (indexPath.section) {
        case 0: // recognitions and tribe reports rows
        case 1:
            return 100;
            break;
        case 2: // individuals section
            return 50;
            break;
        default:
            return 100;
            break;
    }
  
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

@end
