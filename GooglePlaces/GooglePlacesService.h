#import <Foundation/Foundation.h>

@protocol GooglePlacesServiceDelegate;

/// A service for making requests to the Google Places API.
/// See https://developers.google.com/places/documentation/search for documentation.
///
@interface GooglePlacesService : NSObject<NSURLConnectionDataDelegate>

/// The delegate called after completion of a request.
///
@property (nonatomic, weak) id<GooglePlacesServiceDelegate> delegate;

/// The designated initializer.  Creates a new request for searching the Google Places API,
/// with the given API key.
///
/// @param apiKey
///     The API key to be used in all requests made with this service.
///
- (id)initWithAPIKey:(NSString *)apiKey;

/// Searches nearby places at the given location, radius with the given keyword by making a request
/// to the Google Places API.
///
/// @param lat
///     The latitude of the location.
///
/// @param lon
///     The longitude of the location.
///
/// @param radius
///     The radius from location to search, in miles.
///
/// @param keyword
///     The keyword for places to search.
///
- (void)requestPlacesWithLat:(double)lat
                        lon:(double)lon
                     radius:(NSUInteger)radius
                    keyword:(NSString *)keyword;

/// Cancels the current request.  The delegate will not be called.
///
- (void)cancelRequest;

@end
