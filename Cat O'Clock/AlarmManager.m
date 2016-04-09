//
//  AlarmManager.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmManager.h"
#import "AppDelegate.h"
#import "NSDate+Comparison.h"


@interface AlarmManager ()

@property (nonatomic, strong) NSTimer *alarmTimer;

@end

@implementation AlarmManager

@synthesize alarmsArray = _alarmsArray;


#pragma mark - Singleton Method

+ (instancetype)sharedAlarmDataStore
{
    static AlarmManager *_sharedAlarmManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAlarmManager = [[AlarmManager alloc] init];
    });
    
    return _sharedAlarmManager;
}


#pragma mark - Data Store: Setter and Getter / User Defaults Methods

- (NSMutableArray *)alarmsArray
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *decodedAlarmsData = [userDefaults objectForKey: [NSString stringWithFormat:@"alarmsArray"]];
    NSArray *decodedAlarmsArray =[NSKeyedUnarchiver unarchiveObjectWithData:decodedAlarmsData];
    
    _alarmsArray = [decodedAlarmsArray mutableCopy];
    
    return _alarmsArray;
}

- (void)setAlarmsArray:(NSMutableArray *)newArray
{
    if (_alarmsArray != newArray)
    {
        NSMutableArray *mSortedArray = [[NSMutableArray alloc] init];
        
        // Sort array in order of most resent
        NSMutableArray *onAlarms = [[NSMutableArray alloc] init];
        NSMutableArray *offAlarms = [[NSMutableArray alloc] init];
        for (AlarmModel *alarm in newArray) {
            if (alarm.switchState == YES) {
                [onAlarms addObject:alarm];
                [onAlarms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
            } else {
                [offAlarms addObject:alarm];
                [onAlarms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
            }
        }
        for (AlarmModel *alarm in onAlarms) {
            [mSortedArray addObject:alarm];
        }
        for (AlarmModel *alarm in offAlarms) {
            [mSortedArray addObject:alarm];
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedAlarmsData = [NSKeyedArchiver archivedDataWithRootObject:mSortedArray];
        [userDefaults setObject:encodedAlarmsData forKey:[NSString stringWithFormat:@"alarmsArray"]];
    }
}


#pragma mark - Update / Edit Alarm Array Methods

- (void)checkForValidAlarm
{
    NSMutableArray *updatedAlarmsArray = [self.alarmsArray mutableCopy];
    
    [self stopTimer];
    
    for (AlarmModel *firstAlarm in updatedAlarmsArray) {
        if (firstAlarm.switchState == YES) {
        
            NSComparisonResult result = [[NSDate date] compare:firstAlarm.date];
            
            if (result == NSOrderedAscending) {
                [self startTimerWithDate:firstAlarm.date];
                break;
            } else if (result == NSOrderedDescending) {
                break;
            } else if (result == NSOrderedSame) {
                break;
            }
        }
    }
}

- (void)checkForOldAlarm
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    
    for (AlarmModel *thisAlarm in mArray) {
        if ([thisAlarm.date isEarlierThan:[NSDate date]]) {
            thisAlarm.switchState = NO;
        }
    }
    
    [self.alarmsArray removeAllObjects];
    [self setAlarmsArray:mArray];
}

- (void)addAlarmToAlarmArray:(AlarmModel *)newAlarm
{
    NSMutableArray *updatedAlarmsArray = [self.alarmsArray mutableCopy];
    
    if (updatedAlarmsArray == nil) {
        updatedAlarmsArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [newAlarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:newAlarm.timeString withSwitchState:newAlarm.switchState];
    
    [updatedAlarmsArray addObject:updatedAlarm];
    [self setAlarmsArray:updatedAlarmsArray];
}

- (void)updateAlarmInAlarmArray:(NSNumber *)alarmIndex andAlarm:(AlarmModel *)newAlarm
{
    NSMutableArray *updatedAlarmsArray = [self.alarmsArray mutableCopy];
    
    if (updatedAlarmsArray == nil) {
        updatedAlarmsArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [newAlarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:newAlarm.timeString withSwitchState:newAlarm.switchState];
    
    [updatedAlarmsArray removeObjectAtIndex:[alarmIndex intValue]];
    [updatedAlarmsArray insertObject:updatedAlarm atIndex:[alarmIndex intValue]];
    [self setAlarmsArray:updatedAlarmsArray];
}

- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex
{
    NSMutableArray *updatedAlarmsArray = [self.alarmsArray mutableCopy];
    AlarmModel *oldAlarm = updatedAlarmsArray[alarmIndex];
    
    NSDate *nextTime = [oldAlarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:oldAlarm.timeString withSwitchState:!oldAlarm.switchState];
    
    [updatedAlarmsArray removeObjectAtIndex:alarmIndex];
    [updatedAlarmsArray insertObject:updatedAlarm atIndex:alarmIndex];
    [self setAlarmsArray:updatedAlarmsArray];
}

- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex
{
    NSMutableArray *updatedAlarmsArray = [self.alarmsArray mutableCopy];
    
    [updatedAlarmsArray removeObjectAtIndex:alarmIndex];
    [self setAlarmsArray:updatedAlarmsArray];
}


#pragma mark - Audio Player Methods

- (void)startAudioPlayer
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    self.alarmAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    self.alarmAudioPlayer.numberOfLoops = -1;
    self.alarmAudioPlayer.volume = 1;
    
    [self.alarmAudioPlayer play];
}

- (void)stopAudioPlayer
{
    if (self.alarmAudioPlayer) {
        [self.alarmAudioPlayer stop];
        self.alarmAudioPlayer = nil;
    }
}


#pragma mark - Timer Methods

- (void)startTimerWithDate:(NSDate *)date
{
    if (!self.alarmTimer || !self.alarmTimer.valid) {
        self.alarmTimer = [[NSTimer alloc] initWithFireDate:date interval:5.0 target:self selector:@selector(postGifModalViewNotification) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.alarmTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopTimer
{
    if (self.alarmTimer) {
        [self.alarmTimer invalidate];
        self.alarmTimer = nil;
    }
}


#pragma mark - Notification Methods

- (void)postGifModalViewNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"alarmPlaying" object:nil userInfo:nil];;
}

- (void)sendNoticationInAppBackgroundAndInactiveState
{
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        
        NSDate *notificationTimeDelay = [NSDate dateWithTimeIntervalSinceNow:1.0];
        [self setupMeowNoticationWithDate:notificationTimeDelay];
    }
}

- (void)setupMeowNoticationWithDate:(NSDate *)date
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
    [localNotification setAlertBody:@"Meeeeoww!"];
    [localNotification setAlertAction:@"Open App"];
    [localNotification setHasAction:YES];
    [localNotification setFireDate:date];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)setupWarningNotificationWithDate:(NSDate *)date
{
    UILocalNotification *warningNotification = [[UILocalNotification alloc] init];
    [warningNotification setFireDate:date];
    [warningNotification setTimeZone:[NSTimeZone defaultTimeZone]];
    [warningNotification setAlertBody:@"Exiting app disables alarms. Come back to re-activate them."];
    [warningNotification setRepeatInterval:0];
    [warningNotification setSoundName:UILocalNotificationDefaultSoundName];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] scheduleLocalNotification:warningNotification];
    
    // Pausing the processor is necessary in order to make notification fire
    [NSThread sleepForTimeInterval:2];
}

@end

