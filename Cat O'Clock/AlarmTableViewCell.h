//
//  AlarmTableViewCell.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 4/9/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmTableViewCell : UITableViewCell

@property (copy, nonatomic) void (^onSwitchChange)(AlarmTableViewCell *cell);
@property (strong, nonatomic) IBOutlet UIButton *editAlarmButton;
@property (strong, nonatomic) IBOutlet UIView *timeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *switchControl;

@end
