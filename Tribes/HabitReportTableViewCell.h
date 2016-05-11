//
//  HabitReportTableViewCell.h
//  Tribes
//
//  Created by German Espitia on 3/29/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HabitReportTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *username;
@property (strong, nonatomic) IBOutlet UILabel *lastWeekCompletions;
@property (strong, nonatomic) IBOutlet UILabel *thisWeekCompletions;
@property (strong, nonatomic) IBOutlet UILabel *changeOverWeek;
@property (strong, nonatomic) IBOutlet UIImageView *thisWeekCompletionsleftView;
@property (strong, nonatomic) IBOutlet UIImageView *changeLeftView;

@end
