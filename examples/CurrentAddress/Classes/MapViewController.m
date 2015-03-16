/*
     File: MapViewController.m
 Abstract: Controls the map view and manages the reverse geocoder to get the current address.
  Version: 1.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "MapViewController.h"
#import "PlacemarkViewController.h"
#import "GeoJSONSerialization.h"

@interface MapViewController ()

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *getAddressButton;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) MKPlacemark *placemark;
@property (nonatomic, retain) CLLocationManager *locationManager;


@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	   
	// Create a geocoder and save it for later.
    self.geocoder = [[CLGeocoder alloc] init];
    // Blargh
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushToDetail"])
    {
		// Get the destination view controller and set the placemark data that it should display.
        PlacemarkViewController *viewController = segue.destinationViewController;
        viewController.placemark = self.placemark;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	// Center the map the first time we get a real location change.
	static dispatch_once_t centerMapFirstTime;
    static dispatch_once_t grabHexagons;

    
	if ((userLocation.coordinate.latitude != 0.0) && (userLocation.coordinate.longitude != 0.0)) {
//        MKCoordinateSpan mySpan = MKCoordinateSpanMake(0.1,0.1);
//        MKCoordinateRegion myRegion = MKCoordinateRegionMake(userLocation.coordinate, mySpan);
        MKCoordinateRegion myRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 5000, 5000);

        dispatch_once(&centerMapFirstTime, ^{
            [self.mapView setRegion:myRegion animated:YES];
        });

        
        dispatch_once(&grabHexagons, ^{
            NSString *urlString = [NSString stringWithFormat:@"http://wunjo.tennica.net:5000/hex?lon=%f&lat=%f", userLocation.coordinate.longitude, userLocation.coordinate.latitude];
            NSURL *url = [NSURL URLWithString:urlString];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            NSDictionary *geoJSON = [NSJSONSerialization JSONObjectWithData:urlData options:0 error:nil];
            NSArray *shapes = [GeoJSONSerialization shapesFromGeoJSONFeatureCollection:geoJSON error:nil];
            
            for (MKShape *shape in shapes) {
                if ([shape isKindOfClass:[MKPointAnnotation class]]) {
                    [self.mapView addAnnotation:shape];
                } else if ([shape conformsToProtocol:@protocol(MKOverlay)]) {
                    [self.mapView addOverlay:(id <MKOverlay>)shape];
                }
            }
        });

	}
	
	// Lookup the information for the current location of the user.
    [self.geocoder reverseGeocodeLocation:self.mapView.userLocation.location completionHandler:^(NSArray *placemarks, NSError *error) {
		if ((placemarks != nil) && (placemarks.count > 0)) {
			// If the placemark is not nil then we have at least one placemark. Typically there will only be one.
			_placemark = [placemarks objectAtIndex:0];
			
			// we have received our current location, so enable the "Get Current Address" button
			[self.getAddressButton setEnabled:YES];
		}
		else {
			// Handle the nil case if necessary.
		}
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolygonRenderer * polygonView = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
//    polygonView.fillColor   = [UIColor greenColor];
    polygonView.fillColor   = color;
    polygonView.alpha       = 0.25;
    polygonView.strokeColor = [UIColor redColor] ;

    
    polygonView.lineWidth   = 1.0;
    return polygonView;
}


@end
