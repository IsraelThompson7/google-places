#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "GooglePlacesServiceDelegate.h"

/// The root view controller of the main storyboard that displays a map centered on
/// the user's current location with annotations for nearby places.
///
@interface GooglePlacesViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate, GooglePlacesServiceDelegate>

/// The main map view.
///
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
