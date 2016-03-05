//
//  ModalViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "ModalViewController.h"
#import "AlarmManager.h"


@interface ModalViewController ()

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@end

@implementation ModalViewController


#pragma mark - View Lifecyle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Navigation Methods

- (IBAction)endGifAlarm:(id)sender
{
    [[AlarmManager sharedAlarmDataStore] stopTimer];
    [[AlarmManager sharedAlarmDataStore] stopAudioPlayer];
    [self performSegueWithIdentifier:@"showMainView" sender:self];
}

@end
