//
//  TribeReportTableViewCell.h
//  Tribes
//
//  Created by German Espitia on 3/31/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TribeReportTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *lastWeeksCompletions;
@property (strong, nonatomic) IBOutlet UILabel *thisWeeksCompletions;
@property (strong, nonatomic) IBOutlet UILabel *growth;
@property (strong, nonatomic) IBOutlet UIImageView *thisWeeksCompletionsLeftView;
@property (strong, nonatomic) IBOutlet UIImageView *growthLeftView;

@end
