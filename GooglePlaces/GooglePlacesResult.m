#import "GooglePlacesResult.h"

@implementation GooglePlacesResult

- (id)initWithJSONObject:(NSDictionary *)obj
{
    self = [super init];
    if (self) {
        NSDictionary *geometry = [obj objectForKey:@"geometry"];
        NSDictionary *location = [geometry objectForKey:@"location"];
        
        _latitude = [[location objectForKey:@"lat"] doubleValue];
        _longitude = [[location objectForKey:@"lng"] doubleValue];
        
        _name = [obj objectForKey:@"name"];
    }
    return self;
}

@end
