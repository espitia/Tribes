//
//  PremiumViewController.h
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PremiumHibernationSetting,
    PremiumWatcherSetting,
    PremiumWeeklyReport,
    PremiumRemoveAds
} StartingFeatureToSell;


@interface PremiumViewController : UIViewController <UIPageViewControllerDataSource> {
    StartingFeatureToSell startingFeature;
}
- (id)initWithFeature:(StartingFeatureToSell)feature;
@property (strong, nonatomic) UIPageViewController *pageController;

@end

