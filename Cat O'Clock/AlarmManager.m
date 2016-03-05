//
//  AlarmManager.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmManager.h"
#import "NSDate+Comparison.h"
#import "AppDelegate.h"
@import AVFoundation;

@interface AlarmManager ()

@property (nonatomic, strong) NSTimer *alarmTimer;
@property (strong, nonatomic) AVAudioPlayer *alarmAudioPlayer;

@end

@implementation AlarmManager

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

#pragma mark - Initialization Method

- (instancetype)init
{
    self = [super init];
    if (self) {
        _alarmsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Alarm Array Methods

- (void)addAlarmToAlarmArray:(AlarmModel *)newAlarm
{
    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    if (self.alarmsArray == nil) {
        self.alarmsArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [self guaranteeTimeOfFutureDate:newAlarm.date];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:newAlarm.timeString withSwitchState:newAlarm.switchState];
    
    [self.alarmsArray addObject:updatedAlarm];
    [self saveAlarmsToUserDefaults];
}

- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex andAlarm:(AlarmModel *)newAlarm
{
    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    if (self.alarmsArray == nil) {
        self.alarmsArray = [[NSMutableArray alloc] init];
    }
    
    NSDate *nextTime = [self guaranteeTimeOfFutureDate:newAlarm.date];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:newAlarm.timeString withSwitchState:newAlarm.switchState];
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self.alarmsArray insertObject:updatedAlarm atIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex
{
//    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    AlarmModel *oldAlarm = self.alarmsArray[alarmIndex];
    
    NSDate *nextTime = [self guaranteeTimeOfFutureDate:oldAlarm.date];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:oldAlarm.timeString withSwitchState:!oldAlarm.switchState];
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self.alarmsArray insertObject:updatedAlarm atIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex
{
//    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

- (void)checkForValidAlarm
{
//    NSMutableArray *alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    for (AlarmModel *firstAlarm in self.alarmsArray) {
        
        if (firstAlarm.switchState == YES) {
            
            NSDate *today = [NSDate date];
            NSLog(@"Compare today:%@, to Alarm date: %@", today, firstAlarm.date);
            NSComparisonResult result = [today compare:firstAlarm.date];
            
            if (result == NSOrderedAscending) {
                NSLog(@"Future Date %@, Time: %@", firstAlarm.date, firstAlarm.timeString);
                
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
                [localNotification setAlertBody:@"Meeeeoww!"];
                [localNotification setAlertAction:@"Open App"];
                [localNotification setHasAction:YES];
                [localNotification setFireDate:firstAlarm.date];
                [localNotification setSoundName:@"filePath"];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                [self startTimerWithDate:firstAlarm.date];
                
                self.alarmAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
                [self.alarmAudioPlayer prepareToPlay];
                
                break;
            } else if (result == NSOrderedDescending) {
                NSLog(@"Earlier Date %@, Time: %@", firstAlarm.date, firstAlarm.timeString);
                break;
            } else if (result == NSOrderedSame) {
                NSLog(@"Today/Null Date Passed %@", firstAlarm.date);
                break;
            }
        }
    }
}

#pragma mark - Helper Methods

- (void)checkForOldAlarm
{
    NSMutableArray *mArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    for (AlarmModel *thisAlarm in mArray) {
        if ([thisAlarm.date isEarlierThan:[NSDate date]]){
            thisAlarm.switchState = NO;
        }
    }
    
    [self.alarmsArray removeAllObjects];
    self.alarmsArray = mArray;
    [self saveAlarmsToUserDefaults];
}

-(NSDate *)guaranteeTimeOfFutureDate:(NSDate *)date
{
    NSDate *nextTime;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit calendarUnits = NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:calendarUnits fromDate:[NSDate date]];
    components.day += 1;
    NSDate *oneDayFromNow = [calendar dateFromComponents:components];
    
    NSCalendarOptions options = NSCalendarMatchNextTime;
    if ([date isEarlierThan:[NSDate date]]){
        NSDateComponents *oldComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        NSInteger hour = [oldComponents hour];
        NSInteger minute = [oldComponents minute];

        nextTime = [calendar nextDateAfterDate:date matchingHour:hour minute:minute second:0 options:options];
    } else if ([date isLaterThan:oneDayFromNow]) {
        NSDateComponents *oldComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        NSInteger hour = [oldComponents hour];
        NSInteger minute = [oldComponents minute];
        
        nextTime = [calendar dateBySettingHour:hour minute:minute second:0 ofDate:[NSDate date] options:options];
    }
    else {
        nextTime = date;
    }
    
    return nextTime;
}

#pragma mark - User Defaults Methods

- (void)saveAlarmsToUserDefaults
{
    NSMutableArray *mSortedArray = [[NSMutableArray alloc] init];
    NSArray *array = self.alarmsArray;
    
    /*SORT ARRAY IN ORDER OF MOST RESENT*/
    NSMutableArray *onAlarms = [[NSMutableArray alloc] init];
    NSMutableArray *offAlarms = [[NSMutableArray alloc] init];
    for (AlarmModel *alarm in array) {
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
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:mSortedArray];
    [userDefaults setObject:myEncodedObject forKey:[NSString stringWithFormat:@"alarmsArray"]];
}

- (NSArray *)getAlarmsFromUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *myDecodedObject = [userDefaults objectForKey: [NSString stringWithFormat:@"alarmsArray"]];
    NSArray *decodedArray =[NSKeyedUnarchiver unarchiveObjectWithData: myDecodedObject];

    return decodedArray;
}

#pragma mark - Timer Methods

- (void)startTimerWithDate:(NSDate *)date
{
    if (!self.alarmTimer || !self.alarmTimer.valid) {
        self.alarmTimer = [[NSTimer alloc] initWithFireDate:date interval:5.0 target:self selector:@selector(startAudioPlayer) userInfo:nil repeats:YES];
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

#pragma mark - Audio Player Methods

- (void)startAudioPlayer
{
    [self.alarmAudioPlayer play];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"alarmPlaying" object:nil userInfo:nil];
}

- (void)stopAudioPlayer
{
    if (self.alarmAudioPlayer) {
        [self.alarmAudioPlayer stop];
        self.alarmAudioPlayer = nil;
    }
}

@end

