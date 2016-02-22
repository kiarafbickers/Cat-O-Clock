//
//  AddTableViewController.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddTableViewController : UITableViewController

@property (nonatomic, copy) void (^didDismiss)(NSString *data);

@end
