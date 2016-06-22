//
//  AlarmManager.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmManager.h"
#import "AppDelegate.h"
@import AVFoundation;
#import "NSDate+Comparison.h"


@interface AlarmManager ()

@property (nonatomic, strong) NSTimer *alarmTimer;
@property (nonatomic, strong) AVAudioPlayer *alarmAudioPlayer;

@end


@implementation AlarmManager

@synthesize alarmsArray = _alarmsArray;

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

- (NSArray *)alarmsArray
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *decodedAlarmsData = [userDefaults objectForKey: [NSString stringWithFormat:@"alarmsArray"]];
    NSArray *decodedAlarmsArray =[NSKeyedUnarchiver unarchiveObjectWithData:decodedAlarmsData];
    
    if (decodedAlarmsArray == NULL) {
        return @[];
    } else {
        return decodedAlarmsArray;
    }
}

- (void)setAlarmsArray:(NSArray *)newArray
{
    if (![_alarmsArray isEqualToArray:newArray]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedAlarmsData = [NSKeyedArchiver archivedDataWithRootObject:newArray];
        [userDefaults setObject:encodedAlarmsData forKey:[NSString stringWithFormat:@"alarmsArray"]];
    }
}

#pragma mark - Update Alarm Array Methods

- (void)refreshAlarmData
{
    [self checkForExpiredAlarm];
    [self checkForValidAlarm];
}

- (void)checkForValidAlarm
{
    NSMutableArray *mArray= [self.alarmsArray mutableCopy];
    mArray = [self sortArrayByTime];
    for (AlarmModel *firstAlarm in mArray) {
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

- (void)checkForExpiredAlarm
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    
    for (AlarmModel *thisAlarm in mArray) {
        if ([thisAlarm.date isEarlierThan:[NSDate date]]) {
            thisAlarm.switchState = NO;
        }
    }
    
    self.alarmsArray = mArray;
}

#pragma mark - Edit Alarm Array Methods

- (void)addAlarm:(AlarmModel *)alarm
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    
    if (mArray == nil) {
        mArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [alarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:alarm.timeString withSwitchState:alarm.switchState];
    
    [mArray insertObject:updatedAlarm atIndex:0];
    self.alarmsArray = mArray;
}

- (void)updateAlarmAtIndex:(NSNumber *)alarmIndex withAlarm:(AlarmModel *)alarm
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    
    if (mArray == nil) {
        mArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [alarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:alarm.timeString withSwitchState:alarm.switchState];
    
    [mArray removeObjectAtIndex:[alarmIndex intValue]];
    [mArray insertObject:updatedAlarm atIndex:[alarmIndex intValue]];
    self.alarmsArray = mArray;
}

- (void)switchAlarmAtIndex:(NSUInteger)alarmIndex
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    AlarmModel *oldAlarm = mArray[alarmIndex];
    
    NSDate *nextTime = [oldAlarm.date returnTimeOfFutureDate];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:oldAlarm.timeString withSwitchState:!oldAlarm.switchState];
    
    [mArray removeObjectAtIndex:alarmIndex];
    [mArray insertObject:updatedAlarm atIndex:alarmIndex];
    self.alarmsArray = mArray;
}

- (void)removeAlarmAtIndex:(NSUInteger)alarmIndex
{
    NSMutableArray *mArray = [self.alarmsArray mutableCopy];
    
    [mArray removeObjectAtIndex:alarmIndex];
    self.alarmsArray = mArray;
}

- (NSMutableArray *)sortArrayByTime
{
    NSMutableArray *mArray = [NSMutableArray new];
    
    NSMutableArray *onAlarms = [[NSMutableArray alloc] init];
    NSMutableArray *offAlarms = [[NSMutableArray alloc] init];
    for (AlarmModel *alarm in self.alarmsArray) {
        if (alarm.switchState == YES) {
            [onAlarms addObject:alarm];
            [onAlarms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
        } else {
            [offAlarms addObject:alarm];
            [onAlarms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
        }
    }
    for (AlarmModel *alarm in onAlarms) {
        [mArray addObject:alarm];
    }
    for (AlarmModel *alarm in offAlarms) {
        [mArray addObject:alarm];
    }
    
    return mArray;
}

- (AlarmModel *)alarmAtIndex:(NSUInteger)index
{
    NSLog(@"index: %lu", (unsigned long)index);
    return [self.alarmsArray objectAtIndex:index];
}

- (NSUInteger)alarmCount
{
    return self.alarmsArray.count;
}

#pragma mark - Alarm Control Methods

- (void)stopAlarm
{
    [self stopTimer];
    [self stopAudioPlayer];
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
    [self stopTimer];
    
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

#pragma mark - Notification and State Methods

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
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = @"Meeeeoww!";
    localNotification.alertAction = @"Open App";
    localNotification.hasAction = YES;
    localNotification.fireDate = date;
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)setupWarningNotificationWithDate:(NSDate *)date
{
    UILocalNotification *warningNotification = [[UILocalNotification alloc] init];
    warningNotification.timeZone = [NSTimeZone defaultTimeZone];
    warningNotification.alertBody = @"Exiting app disables alarms. Come back to re-activate them.";
    warningNotification.repeatInterval = 0;
    warningNotification.soundName = UILocalNotificationDefaultSoundName;
    warningNotification.fireDate = date;
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] scheduleLocalNotification:warningNotification];
    
    // Pausing the processor is necessary in order to make notification fire
    [NSThread sleepForTimeInterval:2];
}


@end
