//
//  AlarmManager.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmManager.h"
#import "NSDate+Comparison.h"
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
        self.alarmsArray  = [[NSMutableArray alloc] init];
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
    
    [self.alarmsArray addObject:newAlarm];
    [self saveAlarmsToUserDefaults];
}

- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex
{
    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex
{
    self.alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    AlarmModel *oldAlarm = self.alarmsArray[alarmIndex];
    
    NSDate *nextTime;
    if ([oldAlarm.date isEarlierThan:[NSDate date]]){
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *oldComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:oldAlarm.date];
        NSInteger hour = [oldComponents hour];
        NSInteger minute = [oldComponents minute];
        
        NSCalendarOptions options = NSCalendarMatchNextTime;
        nextTime = [calendar nextDateAfterDate:oldAlarm.date matchingHour:hour minute:minute second:0 options:options];
    }
    
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:nextTime WithString:oldAlarm.timeString withSwitchState:!oldAlarm.switchState];
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self.alarmsArray insertObject:updatedAlarm atIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

#pragma mark - User Defaults Methods

- (void)saveAlarmsToUserDefaults
{
    NSArray *array = self.alarmsArray;
    
    /*SORT ARRAY IN ORDER OF MOST RESENT*/
    NSMutableArray *alarms = [[NSMutableArray alloc] init];
    alarms = [array mutableCopy];
    
    [alarms sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES] ]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:alarms];
    [userDefaults setObject:myEncodedObject forKey:[NSString stringWithFormat:@"sample"]];
    [userDefaults synchronize];
}

- (NSArray *)getAlarmsFromUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *myDecodedObject = [userDefaults objectForKey: [NSString stringWithFormat:@"sample"]];
    NSArray *decodedArray =[NSKeyedUnarchiver unarchiveObjectWithData: myDecodedObject];
    
    return decodedArray;
}

#pragma mark - Timer Methods

- (void)startTimerWithDate:(NSDate *)date
{
    if (!self.alarmTimer || !self.alarmTimer.valid) {
        self.alarmTimer = [[NSTimer alloc] initWithFireDate:date interval:5.0 target:self selector:@selector(doTimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.alarmTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void)doTimer
{
    NSLog(@"Alarm Fired from Manager");
    [self.alarmAudioPlayer play];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"timerPlaying" object:nil userInfo:nil];
}

- (void)stopTimer
{
    if (self.alarmAudioPlayer) {
        [self.alarmTimer invalidate];
        self.alarmAudioPlayer = nil;
    }
}

- (void)checkForOldAlarm
{
    [self.alarmsArray removeAllObjects];
    NSMutableArray *mArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    for (AlarmModel *thisAlarm in mArray) {
        if ([thisAlarm.date isEarlierThan:[NSDate date]]){
            thisAlarm.switchState = NO;
        }
        [self.alarmsArray addObject:thisAlarm];
    }
    
    [self saveAlarmsToUserDefaults];
}

- (void)checkForValidAlarm
{
    NSMutableArray *alarmsArray = [[self getAlarmsFromUserDefaults] mutableCopy];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    for (AlarmModel *firstAlarm in alarmsArray) {
        
        if (firstAlarm.switchState == YES) {
            
            NSDate * today = [NSDate date];
            NSComparisonResult result = [today compare:firstAlarm.date];
            switch (result)
            {
                case NSOrderedAscending:
                    NSLog(@"Future Date");
                    
                    [self startTimerWithDate:firstAlarm.date];
                    self.alarmAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
                    [self.alarmAudioPlayer prepareToPlay];
                    self.alarmAudioPlayer.volume = 0.1;
                    self.alarmAudioPlayer.numberOfLoops = -1;
                    
                    break;
                case NSOrderedDescending:
                    NSLog(@"Earlier Date");
                    break;
                case NSOrderedSame:
                    NSLog(@"Today/Null Date Passed"); //Not sure why This is case when null/wrong date is passed
                    break;
                default:
                    NSLog(@"Error Comparing Dates");
                    break;
            }
        }
    }
}

@end

