#import "GooglePlacesViewController.h"
#import "GooglePlacesService.h"
#import "GooglePlacesResult.h"

/// The search radius in meters.
///
NSUInteger const kSearchRadiusMeters = 5000;

/// The region size for centering the map in meters.
///
NSUInteger const kMapRegionDistanceMeters = 1000;

/// The minimum horizontal distance moved between location updates in meters.
///
NSUInteger const kLocationDistanceFilterMeters = 10000;

/// The Google API key used to authorize requests by this application.
///
NSString * const kGoogleApiKey = @"AIzaSyBe8DcADqCxO-Z3CTveMBuYi1B0pbObZ5Q";

/// Internal interface
///
@interface GooglePlacesViewController ()

@property (nonatomic,strong) GooglePlacesService *service;

/// The location manager used to receive location updates.
///
@property (nonatomic,strong) CLLocationManager *locationManager;

/// The list of annotations currently added to the map.
///
@property (nonatomic,strong) NSArray *annotations;

/// The current location of the map.
///
@property (nonatomic,strong) CLLocation *currentLocation;

/// An alert view used to notify the user of errors.
///
@property (nonatomic,strong) UIAlertView *alertView;

@end

@implementation GooglePlacesViewController
@synthesize mapView;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _service = [[GooglePlacesService alloc] initWithAPIKey:kGoogleApiKey];
        _service.delegate = self;        
    }
    
    return self;
}

#pragma mark - Private methods

- (void)reloadAnnotations
{
    // Remove existing annotations from the map.
    [self.mapView removeAnnotations:self.annotations];
            
    [self.service requestPlacesWithLat:self.currentLocation.coordinate.latitude
                                   lon:self.currentLocation.coordinate.longitude
                                radius:kSearchRadiusMeters
                               keyword:@"coffee"];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set ourselves as the delegate of the map view.
    self.mapView.delegate = self;
    
    // Setup the location manager.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kLocationDistanceFilterMeters;
    
    // Start the map at the user's last known location.
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate, kMapRegionDistanceMeters, kMapRegionDistanceMeters);
    [self.mapView setRegion:region animated:NO];
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    [self setMapView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.locationManager startUpdatingLocation];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if (alertView == self.alertView) {
        // If the retry button is pressed, reload at the user's last known location.
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            self.currentLocation = self.locationManager.location;
            
            [self reloadAnnotations];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.alertView = nil;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // Center the map view around the new location.
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, kMapRegionDistanceMeters, kMapRegionDistanceMeters);
    [self.mapView setRegion:region animated:YES];
    
    self.currentLocation = newLocation;
    
    // Reload the annotations at the new location.
    [self reloadAnnotations];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (!self.alertView) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                    message:@"We cannot determine your location."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
        [self.alertView show];
    }
}

#pragma mark - MKMapViewDelegate callbacks

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation
{    
    static NSString *placeAnnotationIdentifier = @"placesAnnotationIdentifier";
    if (annotation != self.mapView.userLocation) {
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:placeAnnotationIdentifier];
        if (!pinView) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:placeAnnotationIdentifier];
            pinView.animatesDrop = YES;
            pinView.canShowCallout = YES;
            pinView.pinColor = MKPinAnnotationColorRed;
        } else {
            pinView.annotation = annotation;
        }
        
        return pinView;
    }
    
    return nil;
}

#pragma mark - GooglePlacesServiceDelegate methods

- (void)placesRequestCompletedWithResults:(NSArray *)results
{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:results.count];
    for (GooglePlacesResult *result in results)
    {
        // Create an annotation.
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(result.latitude, result.longitude);
        annotation.title = result.name;
        [annotations addObject:annotation];
    }
    
    // Keep the annotations for later removal.
    self.annotations = [NSArray arrayWithArray:annotations];
    
    // Add the annotations the map.
    [self.mapView addAnnotations:annotations];    
}

- (void)placesRequestFailedWithError:(NSError *)error
{
    self.annotations = nil;
    
    if (!self.alertView) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Uh oh!"
                                                    message:@"We cannot reach Google's servers."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Retry", nil];
        [self.alertView show];
    }
}

@end
