//
//  PremiumViewController.m
//  Tribes
//
//  Created by German Espitia on 4/5/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "PremiumViewController.h"
#import "PremiumChildViewController.h"

//put the name of your view controller in place of MyViewController
@interface PremiumViewController() 

@end


@implementation PremiumViewController {
    NSArray * images;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // data source of images
    images = @[[UIImage imageNamed:@"hibernation-mode"],[UIImage imageNamed:@"watcher-mode"],
               [UIImage imageNamed:@"remove-ads"],[UIImage imageNamed:@"weekly-report"]];
    
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    PremiumChildViewController *initialViewController = [self viewControllerAtIndex:0];

    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];

    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];

}

#pragma mark - Data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(PremiumChildViewController *)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(PremiumChildViewController *)viewController index];
    
    
    index++;
    
    if (index == 4) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return 4;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

-(PremiumChildViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    PremiumChildViewController *childViewController = [[PremiumChildViewController alloc] initWithNibName:@"PremiumChildViewController" bundle:[NSBundle mainBundle]];
    childViewController.index = index;
    
    dispatch_async(dispatch_get_main_queue(), ^{

    childViewController.backgroundImg.image = [images objectAtIndex:index];
    });
    return childViewController;
    
}






@end
