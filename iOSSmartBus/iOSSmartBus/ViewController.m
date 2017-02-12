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
    [self.btnRouteA setTitle:@"Folsome - Fremon" forState:UIControlStateNormal];
    [self.btnRouteB setTitle:@"Colma - Fremon" forState:UIControlStateNormal];
    [self.btnRouteC setTitle:@"Colma - Orinda" forState:UIControlStateNormal];
    [self.lableRouteA setText:@"5 min"];
    [self.lableRouteB setText:@"10 min"];
    [self.lableRouteC setText:@"16 min"];
    [self.viewRouteA setHidden:YES];
    [self.viewRouteB setHidden:YES];
    [self.viewRouteC setHidden:YES];
    
    [self initPubNub];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initPubNub
{
    // Initialize and configure PubNub client instance
    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-275d4bd0-6556-4125-905c-a9f365a86a37"
                                                                     subscribeKey:@"sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe"];
    self.client = [PubNub clientWithConfiguration:configuration];
    [self.client addListener:self];
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
    
    NSString *fff = @"{\"action\":7}";
//    NSDictionary *fff = @{@"action":@"7"};
    
//    NSError * err;
//    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:fff options:0 error:&err];
//    NSString * myString = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];
    
    [self.client publish:fff
               toChannel:@"Bus_Stop_A"
          storeInHistory:YES
          withCompletion:^(PNPublishStatus *status) {
              if (!status.isError) {
                  NSLog(@"publish successfully");
                  // Message successfully published to specified channel.
              }
              else
              {
                  NSLog(@"Fail");
              }
          }];
    NSLog(@"GO Send A");
}

- (IBAction)btnRouteBClicked:(id)sender {
    [self.client subscribeToChannels:@[@"Bus_Stop_A"] withPresence:YES];
    [self.client subscribeToChannels:@[@"Bus_Stop_B"] withPresence:YES];
    endStop = @"Bus_Stop_B";
}

- (IBAction)btnRouteCClicked:(id)sender {
    [self.client subscribeToChannels:@[@"Bus_Stop_A"] withPresence:YES];
    [self.client subscribeToChannels:@[@"Bus_Stop_C"] withPresence:YES];
    endStop = @"Bus_Stop_C";
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

#pragma mark - PubNub 
// Handle new message from one of channels on which client has been subscribed.
- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    
    // Handle new message stored in message.data.message
    if (![message.data.channel isEqualToString:message.data.subscription]) {
        // Message has been received on channel group stored in message.data.subscription.
    }
    else {
        
        // Message has been received on channel stored in message.data.channel.
    }
    
    NSLog(@"Received message: %@ on channel %@ at %@", message.data.message,
          message.data.channel, message.data.timetoken);
    
    NSLog(@"dataMessageClass: %@", [message.data.message class]);
    
    NSData *objectData = [message.data.message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
    
    NSLog(@"channel: %@", message.data.channel);
    NSString *actionlValue = [jsonDict objectForKey:@"action"];
    NSLog(@"action: %d", [actionlValue intValue]);
    
    
    if ([actionlValue intValue] == 0)
    {
        if ([beginStop isEqualToString:message.data.channel])
        {
            // notify coming bus
        }
        else
        {
            // notify stopping bus
        }
        
        //Virbration
//        [self vibratePhone];
    }
    [self vibratePhone];
}

// Handle subscription status change.
- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    
    if (status.operation == PNSubscribeOperation) {
        
        // Check whether received information about successful subscription or restore.
        if (status.category == PNConnectedCategory || status.category == PNReconnectedCategory) {
            
            // Status object for those categories can be casted to `PNSubscribeStatus` for use below.
            PNSubscribeStatus *subscribeStatus = (PNSubscribeStatus *)status;
            if (subscribeStatus.category == PNConnectedCategory) {
                
                // This is expected for a subscribe, this means there is no error or issue whatsoever.
            }
            else {
                
                /**
                 This usually occurs if subscribe temporarily fails but reconnects. This means there was
                 an error but there is no longer any issue.
                 */
            }
        }
        else if (status.category == PNUnexpectedDisconnectCategory) {
            
            /**
             This is usually an issue with the internet connection, this is an error, handle
             appropriately retry will be called automatically.
             */
        }
        // Looks like some kind of issues happened while client tried to subscribe or disconnected from
        // network.
        else {
            
            PNErrorStatus *errorStatus = (PNErrorStatus *)status;
            if (errorStatus.category == PNAccessDeniedCategory) {
                
                /**
                 This means that PAM does allow this client to subscribe to this channel and channel group
                 configuration. This is another explicit error.
                 */
            }
            else {
                
                /**
                 More errors can be directly specified by creating explicit cases for other error categories
                 of `PNStatusCategory` such as: `PNDecryptionErrorCategory`,
                 `PNMalformedFilterExpressionCategory`, `PNMalformedResponseCategory`, `PNTimeoutCategory`
                 or `PNNetworkIssuesCategory`
                 */
            }
        }
    }
    else if (status.operation == PNUnsubscribeOperation) {
        
        if (status.category == PNDisconnectedCategory) {
            
            /**
             This is the expected category for an unsubscribe. This means there was no error in unsubscribing
             from everything.
             */
        }
    }
    else if (status.operation == PNHeartbeatOperation) {
        
        /**
         Heartbeat operations can in fact have errors, so it is important to check first for an error.
         For more information on how to configure heartbeat notifications through the status
         PNObjectEventListener callback, consult http://www.pubnub.com/docs/ios-objective-c/api-reference#configuration_basic_usage
         */
        
        if (!status.isError) { /* Heartbeat operation was successful. */ }
        else { /* There was an error with the heartbeat operation, handle here. */ }
    }
}

@end
