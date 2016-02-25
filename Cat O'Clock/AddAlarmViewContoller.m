//
//  AddAlarmViewContoller.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AddAlarmViewContoller.h"
#import "AlarmModel.h"
#import "AlarmManager.h"
#import <ChameleonFramework/Chameleon.h>

@interface AddAlarmViewContoller ()

@property (nonatomic, strong) AlarmManager *alarmManager;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIView *datePickerBackroundView;

- (IBAction)dateChanged:(id)sender;
- (IBAction)hideView:(id)sender;

@end

#pragma mark - View Lifecyle Methods

@implementation AddAlarmViewContoller


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor flatBlackColor] colorWithAlphaComponent:0.5f];
    self.datePickerBackroundView.backgroundColor = [UIColor flatWhiteColor];
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Methods

- (IBAction)hideView:(id)sender
{
    [self dismissModal];
}

- (IBAction)back:(id)sender
{
    [self dismissModal];
}

- (IBAction)save:(id)sender
{
    AlarmModel *newAlarm = [[AlarmModel alloc] initWithDate:self.datePicker.date withSwitchState:YES];
    [self.alarmManager addAlarmToAlarmArray:newAlarm];
    [self dismissModal];
}

- (void)dismissModal
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SecondViewControllerDismissed" object:nil userInfo:nil];
}

#pragma mark - Helper Methods

- (void)setDate:(NSDate *)date
{
    self.datePicker.date = date;
}

- (IBAction)dateChanged:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(timeChanged:)]) {
        [self.delegate timeChanged:self.datePicker.date];
    }
}

#pragma mark - Override Methods

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
