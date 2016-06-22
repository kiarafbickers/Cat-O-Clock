//
//  AlarmManager.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlarmModel.h"

@class AlarmManager;

@protocol AlarmManagerDelegate

@optional

@end


@interface AlarmManager : NSObject

@property (nonatomic, weak) id<AlarmManagerDelegate> delegate;
@property (nonatomic, retain) NSArray *alarmsArray;
@property (nonatomic) NSNumber *indexOfAlarm;
@property (nonatomic) BOOL isAlarmToEdit;


+ (instancetype)sharedAlarmDataStore;

- (void)addAlarm:(AlarmModel *)alarm;
- (void)updateAlarmAtIndex:(NSNumber *)alarmIndex withAlarm:(AlarmModel *)alarm;
- (void)switchAlarmAtIndex:(NSUInteger)alarmIndex;
- (void)removeAlarmAtIndex:(NSUInteger)alarmIndex;
- (void)refreshAlarmData;
- (AlarmModel *)alarmAtIndex:(NSUInteger)index;
- (NSUInteger)alarmCount;

- (void)stopAlarm;

- (void)startAudioPlayer;
- (void)stopAudioPlayer;
- (void)startTimerWithDate:(NSDate *)date;
- (void)stopTimer;

@end
