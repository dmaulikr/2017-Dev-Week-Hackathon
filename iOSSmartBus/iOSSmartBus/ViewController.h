//
//  ViewController.h
//  iOSSmartBus
//
//  Created by Leonard Lee on 07/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *txtSource;
@property (weak, nonatomic) IBOutlet UITextField *txtDestination;
@property (weak, nonatomic) IBOutlet UIButton *btnRouteA;
@property (weak, nonatomic) IBOutlet UIButton *btnRouteB;
@property (weak, nonatomic) IBOutlet UIButton *btnRouteC;
@property (weak, nonatomic) IBOutlet UILabel *lableRouteA;
@property (weak, nonatomic) IBOutlet UILabel *lableRouteB;
@property (weak, nonatomic) IBOutlet UILabel *lableRouteC;
@property (weak, nonatomic) IBOutlet UIView *viewRouteA;
@property (weak, nonatomic) IBOutlet UIView *viewRouteB;
@property (weak, nonatomic) IBOutlet UIView *viewRouteC;
@property (weak, nonatomic) IBOutlet UIView *viewAllRoute;
@property (weak, nonatomic) IBOutlet UIView *viewSrcDst;


- (IBAction)btnDestinationClicked:(id)sender;

@end

