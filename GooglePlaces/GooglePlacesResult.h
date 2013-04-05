#import <Foundation/Foundation.h>

/// Represents an individual result retrieved from a Google Places API search.
///
@interface GooglePlacesResult : NSObject

/// The human-readable name for the returned result.
///
@property (nonatomic,readonly,strong) NSString *name;

/// The latitude of the result in signed decimal degrees.
///
@property (nonatomic,readonly) double latitude;

/// The longitude of the result in signed decimal degrees.
///
@property (nonatomic,readonly) double longitude;

/// The designated initalizer.  This method will extract supported fields from the
/// specified JSON object, retrieved from a Google Places search request.
///
- (id)initWithJSONObject:(NSDictionary *)obj;
@end
