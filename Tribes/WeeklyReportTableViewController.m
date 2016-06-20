//
//  WeeklyReportTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/28/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "WeeklyReportTableViewController.h"


@interface WeeklyReportTableViewController ()

@end

@implementation WeeklyReportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Weekly Report 📈";
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"ReportCell" forIndexPath:indexPath];
    


    return cell;

}



@end
