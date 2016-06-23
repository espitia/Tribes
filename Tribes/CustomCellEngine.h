//
//  CustomCellEngine.h
//  Tribes
//
//  Created by German Espitia on 6/20/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tribe.h"

@interface CustomCellEngine : NSObject

typedef enum {
    TypeAddHabitCell = 0,
    TypeAddFriendCell = 1,
    TypePendingMemberCell = 2,
    TypeRegularCell = 4
} TypeOfCustomCell;


@property (nonatomic,strong) Tribe * tribe;

-(instancetype)initWithTribe:(Tribe *)tribeInstance;

-(NSInteger)numberOfRowsForTribe;
-(NSInteger)numberOfCustomRowsForTribe;
-(TypeOfCustomCell)typeOfCellAtIndexPath:(NSIndexPath *)indexPath;
-(BOOL)indexPathIsForCustomCell:(NSIndexPath *)indexPath;
-(UITableViewCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath;
-(NSIndexPath *)indexPathForRegularCellWithIndexPath:(NSIndexPath *)indexPath;

@end
