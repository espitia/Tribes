//
//  CustomCellEngine.m
//  Tribes
//
//  Created by German Espitia on 6/20/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "CustomCellEngine.h"
#import "User.h"

@implementation CustomCellEngine
@synthesize tribe;



-(instancetype)initWithTribe:(Tribe *)tribeInstance{
    self = [super init];
    if(self)
    {
        self.tribe = tribeInstance;
    }
    return self;
}

-(NSInteger)numberOfRowsForTribe {
    
    
    if (tribe.habits.count == 0) {
        return 1;
    }

    if (tribe.membersCount == 0 ||
        [User currentUser].weeklyReportActive ||
        (tribe.onHoldMembers.count > 0 && [[User currentUser] isAdmin:tribe])) {
        return tribe.habits.count + 1;
    }

    return tribe.habits.count;
}


-(TypeOfCustomCell)typeOfCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != 0) {
        return TypeRegularCell;
    }
    if (tribe.habits.count == 0) {
        return TypeAddHabitCell;
    }
    if (tribe.membersCount == 0) {
        return TypeAddFriendCell;
    }
    if (tribe.onHoldMembers.count > 0 && [[User currentUser] isAdmin:tribe]) {
        return TypePendingMemberCell;
    }
    if ([User currentUser].weeklyReportActive) {
        return TypeWeeklyReportCell;
    }
    
    return TypeRegularCell;
}

-(BOOL)indexPathIsForCustomCell:(NSIndexPath *)indexPath {
    return (!([self typeOfCellAtIndexPath:indexPath] == TypeRegularCell)) ? true : false;
}


-(UITableViewCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [[UITableViewCell alloc] init];

    switch ([self typeOfCellAtIndexPath:indexPath]) {
        case TypeAddHabitCell:
            cell.textLabel.text = @"👆 Tap to add a habit";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
            break;
        case TypeAddFriendCell:
            cell.textLabel.text = @"👆 Tap to add a friend";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
            break;
        case TypePendingMemberCell:
            cell.textLabel.text = @"👆 You've got pending members!";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
            break;
        case TypeWeeklyReportCell:
            cell.textLabel.text = @"Weekly report 📈";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        default:
            break;
    }

    return cell;
    
}

-(NSIndexPath *)indexPathForRegularCellWithIndexPath:(NSIndexPath *)indexPath {

    NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - ([self numberOfCustomRowsForTribe]) inSection:indexPath.section];
    return newIndexPath;
}
-(NSInteger)numberOfCustomRowsForTribe {
    return [self numberOfRowsForTribe] - tribe.habits.count;
}
@end
