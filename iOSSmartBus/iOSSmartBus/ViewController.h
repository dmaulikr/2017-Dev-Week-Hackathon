//
//  ViewController.h
//  iOSSmartBus
//
//  Created by Leonard Lee on 07/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *txtDestination;

- (IBAction)btnDestinationClicked:(id)sender;

@end

