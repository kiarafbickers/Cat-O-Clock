//
//  AlarmDataStore.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/18/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmDataStore.h"
@import AVFoundation;

@interface AlarmDataStore ()

@property (nonatomic, strong) NSTimer *base;
@property (strong, nonatomic) AVAudioPlayer *baser;

@end

@implementation AlarmDataStore

#pragma mark - Singleton Method

+ (instancetype)sharedAlarmDataStore
{
    static AlarmDataStore *_sharedAlarmDataStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAlarmDataStore = [[AlarmDataStore alloc] init];
    });
    
    return _sharedAlarmDataStore;
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

#pragma mark - Initialization Method

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
    NSLog(@"alarmsArray = %@", self.alarmsArray);
    
    AlarmModel *oldAlarm = self.alarmsArray[alarmIndex];
    AlarmModel *updatedAlarm = [[AlarmModel alloc] initWithDate:oldAlarm.date WithString:oldAlarm.timeString withSwitchState:!oldAlarm.switchState];
                                
    NSLog(@"remove alarm with switch value %d", oldAlarm.switchState);
    NSLog(@"replace alarm with switch value %d", updatedAlarm.switchState);
    
    [self.alarmsArray removeObjectAtIndex:alarmIndex];
    [self.alarmsArray insertObject:updatedAlarm atIndex:alarmIndex];
    [self saveAlarmsToUserDefaults];
}

#pragma mark - User Defaults Methods

- (void)saveAlarmsToUserDefaults
{
    NSArray *array = self.alarmsArray;
    
    // Sort in most resent
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
    
    for (AlarmModel *alarm in decodedArray) {
        NSLog(@"time = %@", alarm.timeString);
        NSLog(@"switchState = %@", alarm.switchState ? @"ON" : @"OFF");
        NSLog(@"-----------");
    }
    
    return decodedArray;
}

- (void)startBaseWithDate:(NSDate *)date {
    
    if (!self.base || !self.base.valid) {
        self.base = [[NSTimer alloc] initWithFireDate:date
                                             interval:5.0
                                               target:self
                                             selector:@selector(doBase)
                                             userInfo:nil
                                              repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.base forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopBase {
    if (self.base) {
        [self.base invalidate];
        self.base = nil;
    }
}

- (void)doBase {
    [self.baser play];
}


- (void)checkForValidAlarm
{
    AlarmDataStore *dataStore = [AlarmDataStore sharedAlarmDataStore];
    NSMutableArray *alarmsArray = [[dataStore getAlarmsFromUserDefaults] mutableCopy];
    
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
                    [self startBaseWithDate:firstAlarm.date];
                    self.baser = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
                    [self.baser prepareToPlay];
                    self.baser.volume = 0.1;
                    self.baser.numberOfLoops = -1;
                    
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
