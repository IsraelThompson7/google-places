#import "GooglePlacesServiceTest.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"
#import "GooglePlacesResult.h"
#import "MockGooglePlacesServiceDelegate.h"
#import "NoConnectionGooglePlacesService.h"

@interface GooglePlacesServiceTest ()

/// The places request to test.
///
@property (nonatomic, strong) GooglePlacesService *placesService;

/// The delegate that recieves events from a places request.
///
@property (nonatomic, strong) MockGooglePlacesServiceDelegate *placesDelegate;

/// Test JSON data retrieved from the Google Places API.
///
@property (nonatomic, strong) NSData *jsonData;

@end

@implementation GooglePlacesServiceTest

#pragma mark - Setup and teardown methods

- (void)setUp
{
    self.placesService = [[NoConnectionGooglePlacesService alloc] initWithAPIKey:@"testKey"];

    self.placesDelegate = [[MockGooglePlacesServiceDelegate alloc] init];
    self.placesService.delegate = self.placesDelegate;
    
    NSBundle *unitTestBundle = [NSBundle bundleForClass:self.class];
    NSString *jsonPath = [unitTestBundle pathForResource:@"places_example" ofType:@"json"];
    self.jsonData = [NSData dataWithContentsOfFile:jsonPath];
}

- (void)tearDown
{
    [self.placesService cancelRequest];
    self.placesService = nil;
}

#pragma mark - Test methods

- (void)testRequestCreatesURLRequest
{
    NSURL *url = [NSURL URLWithString:@"https://maps.googleapis.com/maps/api/place/search/json?"
                  "key=testKey&location=44.0000000,-93.0000000&radius=10&keyword=test&sensor=true"];
 
    [self.placesService requestPlacesWithLat:44.0
                                        lon:-93.0
                                     radius:10
                                    keyword:@"test"];
    
    STAssertEqualObjects([self.placesService.request URL], url, @"Request should find nearby places using the Google places API.");
}

- (void)testConnectionDidReceiveResponse
{
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    
    [self.placesService connection:nil didReceiveResponse:response];
    
    STAssertNil(self.placesService.connection, @"Should not have a connnection.");
    STAssertEquals(self.placesService.responseData.length, 0U, @"Response data should be empty.");
    STAssertNil(self.placesDelegate.lastError, @"200 response should not generate error.");
}

- (void)testConnectionDidReceiveResponseWithError
{
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:404
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    [self.placesService connection:nil didReceiveResponse:response];
    
    STAssertNotNil(self.placesDelegate.lastError, @"Request should fail with an error.");
    STAssertEquals(self.placesDelegate.lastError.code, 404, @"Request should fail with error code.");
}

- (void)testConnectionFailedWithError
{
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    
    NSError *error = [NSError errorWithDomain:@"FakeConnection" code:42 userInfo:nil];
    [self.placesService connection:nil didFailWithError:error];
    
    STAssertEquals(self.placesDelegate.lastError, error, @"Failed connections should fail with an error.");
}

- (void)testConnectionDidFinishLoading
{
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

    [self.placesService connection:nil didReceiveResponse:response];
    [self.placesService connection:nil didReceiveData:self.jsonData];
    [self.placesService connectionDidFinishLoading:nil];
    
    // Wait for the response to be processed on a background queue.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0L);
    [self.placesDelegate waitUntilRequestCompletes:sema];
    dispatch_release(sema);
    
    STAssertNotNil(self.placesDelegate.lastResults, @"Finished request should have results.");
    STAssertEquals(self.placesDelegate.lastResults.count, 4U, @"Should be 4 places.");
    
    GooglePlacesResult *lastResult = [self.placesDelegate.lastResults lastObject];    
    STAssertEqualObjects(lastResult.name, @"Chinatown Sydney", @"Name should match on result.");
}

@end
