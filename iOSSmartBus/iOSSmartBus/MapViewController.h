//
//  MapViewController.h
//  iOSSmartBus
//
//  Created by Leonard Lee on 11/02/2017.
//  Copyright © 2017 Leonard Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MapViewController : UIViewController <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapView;


@end
