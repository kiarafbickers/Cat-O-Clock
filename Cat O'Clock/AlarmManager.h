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

@property (nonatomic, retain) NSMutableArray *alarmsArray;
@property (nonatomic, strong) NSNumber *alarmToEditNSNumber;
@property (nonatomic) NSInteger alarmToEditAtIndex;
@property (nonatomic) BOOL alarmToEditBool;

+ (instancetype)sharedAlarmDataStore;

- (void)addAlarmToAlarmArray:(AlarmModel *)alarmModel;
- (void)updateAlarmInAlarmArray:(NSNumber *)alarmIndex andAlarm:(AlarmModel *)newAlarm;

- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex;
- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex;

- (void)checkForOldAlarm;
- (void)checkForValidAlarm;

- (void)startTimerWithDate:(NSDate *)date;
- (void)stopTimer;

- (void)stopAudioPlayer;
- (void)startAudioPlayer;

//- (NSArray *)getAlarmsFromUserDefaults;

@end
