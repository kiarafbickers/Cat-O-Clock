//
//  AddAlarmViewContoller.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddAlarmViewContollerDelegate;

@interface AddAlarmViewContoller : UIViewController

@property (nonatomic, assign) id <AddAlarmViewContollerDelegate> delegate;
@property (nonatomic, weak) NSLayoutConstraint *pickerViewVerticalSpaceConstraint;
@property (nonatomic) NSNumber *alarmIndex;
@property (nonatomic) BOOL isAlarmToEdit;

@end

@protocol AddAlarmViewContollerDelegate <NSObject>

@optional
- (void)timeChanged:(NSDate *)date;
- (void)dismissTapped:(AddAlarmViewContoller *)controller;

@end