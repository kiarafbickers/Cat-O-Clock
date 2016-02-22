//
//  AddTableViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AddTableViewController.h"
#import "MainTableViewController.h"
#import "AlarmModel.h"
#import "AlarmManager.h"

@interface AddTableViewController ()

@property (weak, nonatomic) UIDatePicker *datePicker;
@property (nonatomic, strong) AlarmManager *alarmManager;

@end

#pragma mark - View Lifecyle Methods

@implementation AddTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Tableview Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"datePickerCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.datePicker = (UIDatePicker *)[cell viewWithTag:1];
    
    return cell;
}

#pragma mark - Action Methods

- (IBAction)back:(id)sender
{
    [self dismissModal];
}

- (IBAction)save:(id)sender
{
    AlarmModel *newAlarm = [[AlarmModel alloc] initWithDate:self.datePicker.date withSwitchState:YES];
    
    NSLog(@"SAVED newAlarm time %@ and switchstate %i", newAlarm.timeString, newAlarm.switchState);
    
    [self.alarmManager addAlarmToAlarmArray:newAlarm];
    [self dismissModal];
}

- (void)dismissModal
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SecondViewControllerDismissed" object:nil userInfo:nil];
}

@end
