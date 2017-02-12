//
//  MapViewController.h
//  iOSSmartBus
//
//  Created by Leonard Lee on 11/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PubNub/PubNub.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MapViewController : UIViewController <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (nonatomic, strong) PubNub *client;
@property (nonatomic, strong) NSString *beginStop;
@property (nonatomic, strong) NSString *endStop;

@end
