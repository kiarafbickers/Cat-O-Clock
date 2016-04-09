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


#pragma mark - View Lifecycle Methods

@implementation AddAlarmViewContoller

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // create effect
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    // add effect to an effect view
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    UIView *blurView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, (self.view.frame.size.height * 0.55f) - 8)];
    effectView.frame = blurView.frame;

    // add the effect view to the image view
    [self.view addSubview:effectView];
    
//    self.view.backgroundColor = [[UIColor flatBlackColor] colorWithAlphaComponent:0.5f];
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
    if (self.alarmManager.alarmToEditBool == YES) {
        NSNumber *index = self.alarmManager.alarmToEditNSNumber;
        AlarmModel *newAlarm = [[AlarmModel alloc] initWithDate:self.datePicker.date withSwitchState:YES];
        [self.alarmManager updateAlarmInAlarmArray:index andAlarm:newAlarm];
    } else {
        AlarmModel *newAlarm = [[AlarmModel alloc] initWithDate:self.datePicker.date withSwitchState:YES];
        [self.alarmManager addAlarmToAlarmArray:newAlarm];
    }
    
    [self dismissModal];
}

- (void)dismissModal
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SecondViewControllerDismissed" object:nil userInfo:nil];
}

#pragma mark - Date Methods

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
