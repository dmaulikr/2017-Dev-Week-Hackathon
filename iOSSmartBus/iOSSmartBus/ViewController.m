//
//  ViewController.m
//  iOSSmartBus
//
//  Created by Leonard Lee on 07/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioServices.h>
#import <PubNub/PubNub.h>
#import "MapViewController.h"

@interface ViewController () <PNObjectEventListener> {
    //Picker View
    UIPickerView *picker;
    
    NSArray *stopArray;
    NSString *beginStop;
    NSString *endStop;
}

@property (nonatomic, strong) PubNub *client;

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
    
    stopArray = [[NSArray alloc]initWithObjects:@"A", @"B", @"C", nil];
    
    
    
    // hard code for those info
    [self.btnRouteA setTitle:@"SF - SJSU" forState:UIControlStateNormal];
    [self.btnRouteB setTitle:@"DalyCity - SJSU" forState:UIControlStateNormal];
    [self.btnRouteC setTitle:@"DalyCity - Santa Clara" forState:UIControlStateNormal];
    [self.lableRouteA setText:@"5 min"];
    [self.lableRouteB setText:@"10 min"];
    [self.lableRouteC setText:@"16 min"];
    [self.viewRouteA setHidden:YES];
    [self.viewRouteB setHidden:YES];
    [self.viewRouteC setHidden:YES];
    
    [self.viewRouteA.layer setCornerRadius:20.f];
    [self.viewRouteB.layer setCornerRadius:20.f];
    [self.viewRouteC.layer setCornerRadius:20.f];
    [self.viewAllRoute.layer setCornerRadius:20.f];
    [self.viewAllRoute.layer setShadowOffset:CGSizeMake(20, 10)];
    [self.viewSrcDst.layer setCornerRadius:20.f];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initPubNub:(PubNub *)client
{
    // Initialize and configure PubNub client instance
    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-275d4bd0-6556-4125-905c-a9f365a86a37"
                                                                     subscribeKey:@"sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe"];
    client = [PubNub clientWithConfiguration:configuration];
    [client addListener:self];
}

#pragma mark - Picker View Delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [stopArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.txtDestination.text = [stopArray objectAtIndex:row];
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
    if (![self.txtDestination.text isEqualToString:@""])
    {
        beginStop = @"Bus_Stop_A";
        
        // ready to appear route options for buttons
        [self.viewRouteA setHidden:NO];
        [self.viewRouteB setHidden:NO];
        [self.viewRouteC setHidden:NO];
    }
}

#pragma mark - Button Click
- (IBAction)btnDestinationClicked:(id)sender
{
    // unsubscribe
    [self.client unsubscribeFromAll];
}

- (IBAction)btnRouteAClicked:(id)sender {
    [self.client subscribeToChannels:@[@"Bus_Stop_A"] withPresence:YES];
    endStop = @"Bus_Stop_A";
    
    [self performSegueWithIdentifier:@"mapSeque" sender:self];
}

- (IBAction)btnRouteBClicked:(id)sender {
    endStop = @"Bus_Stop_B";
    
    [self performSegueWithIdentifier:@"mapSeque" sender:self];
}

- (IBAction)btnRouteCClicked:(id)sender {
    endStop = @"Bus_Stop_C";
    
    [self performSegueWithIdentifier:@"mapSeque" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"mapSeque"])
    {
        // Get reference to the destination view controller
        MapViewController *vc = [segue destinationViewController];
        vc.beginStop = beginStop;
        vc.endStop = endStop;
        
        [self initPubNub:vc.client];
        [vc.client subscribeToChannels:@[beginStop] withPresence:YES];
        [vc.client subscribeToChannels:@[endStop] withPresence:YES];
        
        // publich to start stop
        NSString *sendMsg = @"luckmanlluckmanqactionluckmanqluckmanm7luckmanr";
        
        [vc.client publish:sendMsg
                   toChannel:beginStop
              storeInHistory:YES
              withCompletion:^(PNPublishStatus *status) {
                  if (!status.isError) {
                      NSLog(@"publish successfully");
                      // Message successfully published to specified channel.
                  }
                  else
                  {
                      NSLog(@"Fail publishing");
                  }
              }];
        
        // Pass any objects to the view controller here, like...
        
    }
}

@end
