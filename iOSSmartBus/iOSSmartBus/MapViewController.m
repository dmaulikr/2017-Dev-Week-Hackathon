//
//  MapViewController.m
//  iOSSmartBus
//
//  Created by Leonard Lee on 11/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import "MapViewController.h"
#import <AudioToolbox/AudioServices.h>

@interface MapViewController () <PNObjectEventListener> {
    GMSMapView *map;
    GMSMarker *bus;
}

@end

@implementation MapViewController

- (void)loadView {
    [super loadView];
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
    GMSCameraPosition *center = [GMSCameraPosition cameraWithLatitude:37.44198
                                                              longitude:-121.99292
                                                                   zoom:10];
    map = [GMSMapView mapWithFrame:self.mapView.bounds camera:center];
    [self.mapView addSubview:map];
    map.myLocationEnabled = NO;
    
    
    NSArray* arrMarkerData = @[
                               @{@"title": @"Bus Stop A", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.44198 longitude:-122.14292]},
                               @{@"title": @"Bus Stop B", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.42798 longitude:-122.10125]},
                               @{@"title": @"Bus Stop C", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.40809 longitude:-122.06867]},
                               @{@"title": @"Bus Stop D", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.39971 longitude:-122.0354]},
                               @{@"title": @"Bus Stop E", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.40373 longitude:-122.02285]},
                               @{@"title": @"Bus Stop F", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.41854 longitude:-121.9701]},
                               @{@"title": @"Bus Stop G", @"snippet": @"SJSU", @"position": [[CLLocation alloc]initWithLatitude:37.4294 longitude:-121.9097]},
                               ];
    
    for (NSDictionary* dict in arrMarkerData)
    {
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.icon = [UIImage imageNamed:@"one.png"];
        marker.position = [(CLLocation*)dict[@"position"] coordinate];
        marker.title = dict[@"title"];
        marker.snippet = dict[@"snippet"];
        marker.appearAnimation = kGMSMarkerAnimationPop;
        marker.map = map;
    }

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    bus = [[GMSMarker alloc] init];
    bus.icon = [UIImage imageNamed:@"Bus.png"];
    bus.title = @"bus1";
    bus.snippet = @"bus1";
    bus.appearAnimation = kGMSMarkerAnimationPop;
    bus.map = map;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    [map animateToLocation:marker.position];
    return YES;
}

#pragma mark - PubNub
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
    
    NSData *objectData = [message.data.message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
    
    NSString *actionlValue = [jsonDict objectForKey:@"action"];
    if ([message.data.channel isEqualToString:@"All_Bus_Info"]) {
        Float32 longitude = [[jsonDict objectForKey:@"longitude"] floatValue];
        NSLog(@"longitude: %f", longitude);
        Float32 latitude = [[jsonDict objectForKey:@"latitude"] floatValue];
        NSLog(@"latitude: %f", longitude);
        
        bus.position = [[[CLLocation alloc]initWithLatitude:latitude longitude:longitude] coordinate];
        // marker postiton

    }

    // always receive notification, check the logic itself
    {
        NSLog(@"------------------------------------------------------------");
        // 0 進站
        if ((actionlValue != nil) && ([actionlValue intValue] == 0))
        {
            if ([self.beginStop isEqualToString:message.data.channel])
            {
                // notify coming bus here
                [self vibratePhone];
                [self.mesgLabel setText:@"Arriving"];
                
            }
            else if ([self.endStop isEqualToString:message.data.channel])
            {
                // notify stopping bus here
                [self vibratePhone];
                [self.mesgLabel setText:@"Arriving"];
            }
        }
        else
        {
            // other actions
            [self.mesgLabel setText:@"On the way"];
        }
    }
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
