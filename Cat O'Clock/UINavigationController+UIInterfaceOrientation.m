//
//  UINavigationController+UIInterfaceOrientation.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "UINavigationController+UIInterfaceOrientation.h"

@implementation UINavigationController (UIInterfaceOrientation)

- (BOOL)shouldAutorotate
{
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
