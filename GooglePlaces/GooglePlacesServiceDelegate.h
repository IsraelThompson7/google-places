#import <Foundation/Foundation.h>

@class GooglePlacesService;

@protocol GooglePlacesServiceDelegate <NSObject>

/// Called whenever a place search request succeeds with an array of PlaceSearchResult objects.
///
- (void)placesRequestCompletedWithResults:(NSArray *)results;

/// Called whenever a place search request failed with the error that occurred.
///
- (void)placesRequestFailedWithError:(NSError *)error;

@end
