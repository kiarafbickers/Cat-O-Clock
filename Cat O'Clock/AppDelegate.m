//
//  AppDelegate.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#import "AppDelegate.h"
#import "AlarmManager.h"
#import "AlarmModel.h"
#import "MMPDeepSleepPreventer.h"
#import "MainTableViewController.h"
@import AVFoundation;

@interface AppDelegate ()

@property (strong, nonatomic) AVAudioPlayer *alarmAudioPlayer;
@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (nonatomic, strong) MMPDeepSleepPreventer *sleepPreventer;
@property (nonatomic) NSTimeInterval timeDifference;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    /* CHECK PERMISSIONS */
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    
    /* ENABLE AUDIO */
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    [self.alarmManager checkForOldAlarm];
    [self.alarmManager checkForValidAlarm];
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        NSLog(@"Recieved Notification %@", localNotification);
    }
    UILocalNotification *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        NSLog(@"Recieved Notification %@", remoteNotification);
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"WillResignActive");
    
    [self.sleepPreventer startPreventSleep];
    [self configureBackroundSoundWithNoVolume];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    NSLog(@"Canceled all notications to create new ones.");
    
    //self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    for (AlarmModel *alarm in self.alarmManager.alarmsArray) {
        if (alarm.switchState == YES) {
            
            NSLog(@"Set alarm notification for: %@", alarm.timeString);
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [localNotification setAlertBody:@"Meeeeoww!"];
            [localNotification setAlertAction:@"Open App"];
            [localNotification setHasAction:YES];
            [localNotification setFireDate:alarm.date];
            [localNotification setSoundName:filePath];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            [self.alarmManager startTimerWithDate:alarm.date];
            
            self.timeDifference = [alarm.date timeIntervalSinceDate:[NSDate date]];
            NSLog(@"diff %fs", self.timeDifference);
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    

    // Not sure what about this is making it work but the below code is necessary for alarm to play in backround.
    UIBackgroundTaskIdentifier longTask;
    longTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
        // If you’re worried about exceeding 10 minutes, handle it here
        NSTimer *alarmTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeDifference target:self selector:@selector(functionYouWantToRunInTheBackground) userInfo:nil repeats:NO];
        if (alarmTimer) {
            NSLog(@"alarmTimer set to timer %@", alarmTimer.fireDate);
        }
    }];
}

-(void) functionYouWantToRunInTheBackground
{
    NSLog(@"functionYouWantToRunInTheBackground");
    self.backgroundUploadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
    
    for (AlarmModel *alarm in self.alarmManager.alarmsArray) {
        if (alarm.switchState == YES) {
            
            NSLog(@"Set alarm notification for: %@", alarm.timeString);
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [localNotification setAlertBody:@"Meeeeoww!"];
            [localNotification setAlertAction:@"Open App"];
            [localNotification setHasAction:YES];
            [localNotification setFireDate:alarm.date];
            [localNotification setSoundName:filePath];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            [self.alarmManager startTimerWithDate:alarm.date];
            
            self.timeDifference = [alarm.date timeIntervalSinceDate:[NSDate date]];
            NSLog(@"diff %fs", self.timeDifference);
        }
    }
}

-(void) endBackgroundUpdateTask
{
    NSLog(@"endBackgroundUpdateTask");
    
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundUploadTask];
    self.backgroundUploadTask = UIBackgroundTaskInvalid;
}




- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"WillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"DidBecomeActive, disabled sleep preventer");
    
    [self.sleepPreventer stopPreventSleep];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"WillTerminate!");
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    if(IS_OS_8_OR_LATER)
    {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    
    for (AlarmModel *alarm in self.alarmManager.alarmsArray) {
        
        if (alarm.switchState == YES) {
            
            if (application.applicationIconBadgeNumber == 0) {
                [application setApplicationIconBadgeNumber:1];
            }
            
            NSDate *warningNotificationTimeDelay = [NSDate dateWithTimeIntervalSinceNow:3.0];
            UILocalNotification *warningNotification = [[UILocalNotification alloc] init];
            [warningNotification setFireDate:warningNotificationTimeDelay];
            [warningNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [warningNotification setAlertBody:@"Exiting app disables alarms. Come back to re-activate them."];
            [warningNotification setRepeatInterval:0];
            [warningNotification setSoundName:UILocalNotificationDefaultSoundName];
            [[UIApplication sharedApplication] scheduleLocalNotification:warningNotification];
            
            // Pausing the processor is necessary in order to make notification fire
            [NSThread sleepForTimeInterval:2];
            
            NSLog(@"Set alarm warning!!");
            break;
        }
    }
    
    [self.alarmManager.alarmsArray removeAllObjects];
    
    [self.alarmManager stopTimer];
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self.alarmManager stopAudioPlayer];
}

#pragma mark - Helper Methods

- (void)configureBackroundSoundWithNoVolume
{
    NSString *backgroundNilPath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *backgroundNilURL = [NSURL fileURLWithPath:backgroundNilPath];
    AVAudioPlayer *backgroundNilPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundNilURL error:nil];
    backgroundNilPlayer.numberOfLoops = -1;
    backgroundNilPlayer.volume = 0.1;
}


@end
