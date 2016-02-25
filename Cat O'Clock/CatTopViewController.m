//
//  MasterViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "TopViewController.h"
#import "BreadCrumbView.h"
#import <ChameleonFramework/Chameleon.h>

@interface TopViewController ()

@property (nonatomic, strong) NSUserDefaults *theDefaults;
@property (assign, nonatomic) NSInteger currentView;
@property (weak, nonatomic) IBOutlet UIView *backroundView;
@property (strong, nonatomic) UILabel *message;

@property (weak, nonatomic) IBOutlet UILabel *swipeForNextViewLabel;
@property (strong, nonatomic) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;

@property (strong, nonatomic) CABasicAnimation *fadeIn;
@property (strong, nonatomic) CABasicAnimation *fadeOut;

@property (weak, nonatomic) IBOutlet UIView *containerBreadCrumbView;
@property (nonatomic, strong) UIView *breadcrumbsView;
@property (nonatomic, strong) UIImageView *breadcrumbsImageView;
@property (nonatomic, strong) UIImage *breadcrumbsImage;

@property (strong, nonatomic) BreadCrumbView *breadCrumbView;

@end

@implementation TopViewController

#pragma mark - View Lifecyle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    BOOL firstLaunch = [self checkFirstLaunch];
//    if (firstLaunch == YES) {
//        [self setupGestures];
//        self.view.backgroundColor = [UIColor flatBlackColor];
//    } else {
//        [self performSegueWithIdentifier:@"showMainTableView" sender:self];
//    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)checkFirstLaunch
{
    NSUInteger launchCount;
    launchCount = [self.theDefaults integerForKey:@"hasRun"] + 1;
    [self.theDefaults setInteger:launchCount forKey:@"hasRun"];
    [self.theDefaults synchronize];
    
    NSLog(@"This application has been run %lu amount of times", (unsigned long)launchCount);
    
    BOOL firstLaunch = false;
    if(launchCount == 1) {
        NSLog(@"This is the first time this application has been run");
        firstLaunch = YES;
    }
    
    if(launchCount >= 2) {
        NSLog(@"This application has been run before");
        firstLaunch = NO;
    }
    
    return firstLaunch;
}

- (void)setupGestures
{
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    
//    self.fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    self.fadeIn.duration = 2.0f;
//    self.fadeIn.fromValue = @0.0f;
//    self.fadeIn.toValue = @1.0f;
//    self.fadeIn.removedOnCompletion = NO;
//    self.fadeIn.fillMode = kCAFilterLinear;
//    self.fadeIn.additive = NO;
//    
//    self.fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    self.fadeOut.duration = 2.0f;
//    self.fadeOut.fromValue = @1.0f;
//    self.fadeOut.toValue = @0.0f;
//    self.fadeOut.removedOnCompletion = NO;
//    self.fadeOut.fillMode = kCAFilterLinear;
//    self.fadeOut.additive = NO;
}

#pragma mark - Gestures

- (void)handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        CGPoint labelPosition = CGPointMake(self.swipeForNextViewLabel.frame.origin.x - 100.0, self.swipeForNextViewLabel.frame.origin.y);
        self.swipeForNextViewLabel.frame = CGRectMake( labelPosition.x , labelPosition.y , self.swipeForNextViewLabel.frame.size.width, self.swipeForNextViewLabel.frame.size.height);
        [self transitionToNextView];
        
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        CGPoint labelPosition = CGPointMake(self.swipeForNextViewLabel.frame.origin.x + 100.0, self.swipeForNextViewLabel.frame.origin.y);
        self.swipeForNextViewLabel.frame = CGRectMake( labelPosition.x , labelPosition.y , self.swipeForNextViewLabel.frame.size.width, self.swipeForNextViewLabel.frame.size.height);
        [self transitionToNextView];
    }
}

#pragma mark - Actions

-(void)transitionToNextView
{
    self.currentView++;
    
    BreadCrumbView *nextView = [self nextView];
    [nextView addGestureRecognizer:self.rightSwipeGestureRecognizer];
    nextView.alpha = 0.0;
    [self.view insertSubview:nextView aboveSubview:self.swipeForNextViewLabel];
    
    [UIView animateWithDuration:0.5 animations:^{
        nextView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self.containerBreadCrumbView removeFromSuperview];
        self.containerBreadCrumbView = nextView;
    }];
    
}

-(BreadCrumbView *)nextView
{
    switch (self.currentView)
    {
        case 0:
        {
            self.breadCrumbView = [[BreadCrumbView alloc] init];
            
            // Set UILabel text
            self.message = [UILabel new];
            self.message.backgroundColor = [UIColor clearColor];
            self.message.text = @"Congrats on your new pet!\n \n";
            self.message.font = [UIFont fontWithName:@"Helvetica" size:20];
            self.message.numberOfLines = 3;
            self.message.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:self.message];
            
            // Creating constraints using Layout Anchors
            self.message.translatesAutoresizingMaskIntoConstraints = NO;
            [self.message.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
            [self.message.centerYAnchor constraintEqualToAnchor:self.view.topAnchor constant:100].active = YES;
            [self.message.widthAnchor constraintEqualToConstant:300.0f].active = YES;
            [self.message.heightAnchor constraintEqualToConstant:150.0f].active = YES;
            
            // Add breadcrumbs image
            self.breadcrumbsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 88.0, 7.0)];
            self.breadcrumbsImage = [UIImage imageNamed:@"page1"];
            self.breadcrumbsImageView = [[UIImageView alloc] initWithImage:self.breadcrumbsImage];
            self.breadcrumbsImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.breadcrumbsImageView.frame = self.breadcrumbsView.bounds;
            [self.view addSubview:self.breadcrumbsImageView];
            [self.view addSubview:self.breadcrumbsView];
            
            CGRect viewBounds2 = [[self view] frame];
            [self.breadcrumbsImageView.layer setPosition:CGPointMake(viewBounds2.size.width / 2.0, viewBounds2.size.height / 1.04 - viewBounds2.origin.y)];
            
            return self.breadCrumbView;
        }
        case 1:
        {
            self.message.text = @"Every morning his water\nstarts out low...";

            self.breadcrumbsImageView.image = [UIImage imageNamed:@"page2"];
            
            return self.breadCrumbView;
        }
        case 2:
        {
            self.message.text = @"As you drink,\nhis water level rises.";
            
            self.breadcrumbsImageView.image = [UIImage imageNamed:@"page3"];
            
            return self.breadCrumbView;
        }
        default:
        {
            self.currentView = 0;
            return [self nextView];
        }
    }
    return nil;
}




@end
