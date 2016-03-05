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
#import "MainTableViewController.h"
@import AVFoundation;

@interface AppDelegate ()

@property (strong, nonatomic) AVAudioPlayer *alarmAudioPlayer;
@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (nonatomic) NSTimeInterval timeDifference;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //NSLog(@"application didFinishLaunchingWithOptions");
    
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
    
    //NSLog(@"stopBackgroundTask");
    [self stopBackgroundTask];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //NSLog(@"DidBecomeActive");
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //NSLog(@"WillResignActive");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //NSLog(@"WillEnterForeground");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //NSLog(@"applicationDidEnterBackground");

    self.backgroundTask = [[BackgroundTask alloc] init];
    //NSLog(@"self.backgroundTask %@", self.backgroundTask);
    
    // Handle events exceeding 3-10 minutes here
    //NSLog(@"########");
    [self functionYouWantToRunInTheBackground];
    
    [self startBackgroundTask];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //NSLog(@"WillTerminate!");
    
    [self.alarmManager stopTimer];
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self.alarmManager stopAudioPlayer];
    
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
            
            //NSLog(@"Set alarm warning!!");
            break;
        }
    }
    
    [self.alarmManager.alarmsArray removeAllObjects];
}

#pragma mark - Backround Methods

-(void) backgroundCallback:(id)info
{
    //NSLog(@"########");
    //NSLog(@"###### BG TASK RUNNING:%f", [UIApplication sharedApplication].backgroundTimeRemaining);
}

-(void) startBackgroundTask
{
    //NSLog(@"startBackgroundTask");
    [self.backgroundTask startBackgroundTasks:2 target:self selector:@selector(backgroundCallback:)];
}

-(void) stopBackgroundTask
{
    [self.backgroundTask stopBackgroundTask];
}

-(void) functionYouWantToRunInTheBackground
{
    //NSLog(@"functionYouWantToRunInTheBackground");
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    //NSLog(@"Canceled all notications to create new ones.");
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    
    for (AlarmModel *alarm in self.alarmManager.alarmsArray) {
        if (alarm.switchState == YES) {
            
            //NSLog(@"Set alarm notification for: %@", alarm.timeString);
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [localNotification setAlertBody:@"Meeeeoww!"];
            [localNotification setAlertAction:@"Open App"];
            [localNotification setHasAction:YES];
            [localNotification setFireDate:alarm.date];
            [localNotification setSoundName:filePath];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            [self.alarmManager startTimerWithDate:alarm.date];
            
            self.alarmAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
            [self.alarmAudioPlayer prepareToPlay];
        }
    }
}

@end
