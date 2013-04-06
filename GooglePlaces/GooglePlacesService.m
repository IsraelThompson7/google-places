#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"
#import "GooglePlacesServiceDelegate.h"
#import "GooglePlacesResult.h"

@implementation GooglePlacesService

#pragma mark - Init methods

- (id)initWithAPIKey:(NSString *)apiKey
{
    self = [super init];
    
    if (self) {
        _apiKey = apiKey;
    }
    
    return self;
}

#pragma mark - Private methods

- (NSURL *)URLWithLat:(double)lat lon:(double)lon radius:(int)radius keyword:(NSString *)keyword
{
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/"
                           "search/json?key=%@&location=%.7f,%.7f&radius=%d&keyword=%@&sensor=true",
                           self.apiKey,
                           lat,lon,
                           radius,
                           keyword];

    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return url;
}

#pragma mark - Instance methods

- (void)requestPlacesWithLat:(double)lat
                        lon:(double)lon
                     radius:(NSUInteger)radius
                    keyword:(NSString *)keyword
{
    NSURL *url = [self URLWithLat:lat lon:lon radius:radius keyword:keyword];
    self.request = [NSURLRequest requestWithURL:url];
    
    // Cancel any in flight requests.
    [self.connection cancel];
    
    // Create a buffer to handle the response.
    self.responseData = [NSMutableData data];
    
    [self startRequest];
}

- (void)cancelRequest
{
    [self.connection cancel];
    self.connection = nil;
}

- (void)startRequest
{
    self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ([httpResponse statusCode] == 200)
    {
        [self.responseData setLength:0];
    }
    else
    {
        NSError *error = [NSError errorWithDomain:GooglePlacesServiceDomain
                                             code:[httpResponse statusCode]
                                         userInfo:nil];
        [self.delegate placesRequestFailedWithError:error];
        
        [self cancelRequest];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // As bytes arrive, append them to the buffer.    
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Connection is complete, jump to a background queue to process the response.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&jsonError];
        NSArray *jsonResults = [json objectForKey:@"results"];
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:jsonResults.count];
        
        // Create place results out of the JSON response.
        for (NSDictionary *jsonResult in jsonResults)
        {
            [results addObject:[[GooglePlacesResult alloc] initWithJSONObject:jsonResult]];
        }
        
        if (jsonError) {
            [self.delegate placesRequestFailedWithError:jsonError];
        } else {
            [self.delegate placesRequestCompletedWithResults:results];
        }
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // Notify our delegate that an error occurred.
    [self.delegate placesRequestFailedWithError:error];
}

@end
