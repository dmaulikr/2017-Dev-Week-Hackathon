//
//  ViewController.m
//  iOSSmartBus
//
//  Created by Leonard Lee on 07/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioServices.h>

@interface ViewController (){
    //Picker View
    UIPickerView *picker;
    
    NSArray *stopArray;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Gesture Init
    //Gesture Delegate
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(tapGesture:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    // picker view initialize
    picker = [[UIPickerView alloc]init];
    picker.dataSource = self;
    picker.delegate = self;
    [picker selectRow:0 inComponent:0 animated:YES];
    
    stopArray = [[NSArray alloc]initWithObjects:@"A", @"B", @"C", @"D"
                , @"E", @"F", @"G", @"H"
                , @"H", @"J", nil];
    
    self.txtDestination.inputView = picker;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Picker View Delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [stopArray objectAtIndex:row];
}

#pragma mark - Picker View Data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return stopArray.count;
}

#pragma mark - Gesture Responder
- (void)tapGesture:(UITapGestureRecognizer *)gestureRecognizer {
    [self.view endEditing:YES];
}

#pragma mark - Button Click
- (IBAction)btnDestinationClicked:(id)sender {
    //subcribe to PubNub
    
    //Virbration
    [self vibratePhone];
}

- (void)vibratePhone;
{
    if([[UIDevice currentDevice].model isEqualToString:@"iPhone"]) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); //works ALWAYS as of this post
    }
    else {
        // Not an iPhone, so doesn't have vibrate
        // play the less annoying tick noise or one of your own
        AudioServicesPlayAlertSound(1105);
    }
}
@end
