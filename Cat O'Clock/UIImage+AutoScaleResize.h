//
//  UIImage+AutoScaleResize.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/22/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (AutoScaleResize)

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
