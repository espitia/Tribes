//
//  RecognitionTableViewCell.h
//  Tribes
//
//  Created by German Espitia on 3/28/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface RecognitionTableViewCell : UITableViewCell
@property (atomic, strong) User * user;
@property (strong, nonatomic) IBOutlet UILabel *recognitionTitle;
@property (strong, nonatomic) IBOutlet UILabel *member;
@property (strong, nonatomic) IBOutlet UILabel *emojiReward;

@end
