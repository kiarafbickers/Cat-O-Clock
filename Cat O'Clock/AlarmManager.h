//
//  AlarmManager.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlarmModel.h"

@interface AlarmManager : NSObject

@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (nonatomic) NSNumber *alarmToEditNSNumber;
@property (nonatomic) NSInteger alarmToEditAtIndex;
@property (nonatomic) BOOL alarmToEditBool;

+ (instancetype)sharedAlarmDataStore;
- (void)addAlarmToAlarmArray:(AlarmModel *)alarmModel;
- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex;
- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex;
- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex andAlarm:(AlarmModel *)newAlarm;

- (void)checkForOldAlarm;
- (void)checkForValidAlarm;

- (void)startTimerWithDate:(NSDate *)date;
- (void)stopAlarmTimer;
- (void)stopAudioPlayer;
- (void)doTimer;

- (NSArray *)getAlarmsFromUserDefaults;

@end
