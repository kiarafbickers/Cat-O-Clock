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
@property (weak, nonatomic) NSLayoutConstraint *pickerViewVerticalSpaceConstraint;

@end


@protocol AddAlarmViewContollerDelegate <NSObject>

@optional
- (void)timeChanged:(NSDate *)date;
- (void)dismissTapped:(AddAlarmViewContoller *)controller;


@end