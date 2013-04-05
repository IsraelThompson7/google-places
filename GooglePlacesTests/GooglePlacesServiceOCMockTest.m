#import "GooglePlacesServiceOCMockTest.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"
#import "GooglePlacesServiceDelegate.h"
#import "GooglePlacesResult.h"
#import <OCMock/OCMock.h>

@interface GooglePlacesServiceOCMockTest ()

/// The places service to test.
///
@property (nonatomic, strong) id placesService;

/// Test JSON data retrieved from the Google Places API.
///
@property (nonatomic, strong) NSData *jsonData;

/// A successful response with response code 200.
///
@property (nonatomic, strong) NSHTTPURLResponse *successfulResponse;

/// A failed response with response code 404.
///
@property (nonatomic, strong) NSHTTPURLResponse *failedResponse;

@end

@implementation GooglePlacesServiceOCMockTest

#pragma mark - Setup and teardown methods

- (void)setUp
{
    // The service we'll be testing.
    GooglePlacesService *placesService = [[GooglePlacesService alloc] initWithAPIKey:@"testKey"];
    
    // Create a partial mock that stubs the startRequest method to prevent actual connections.
    self.placesService = [OCMockObject partialMockForObject:placesService];
    [[self.placesService stub] startRequest];
    
    self.successfulResponse = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                          statusCode:200
                                                         HTTPVersion:nil
                                                        headerFields:nil];
    
    self.failedResponse = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                      statusCode:404
                                                     HTTPVersion:nil
                                                    headerFields:nil];

    // Load an example json from the test bundle.
    NSBundle *unitTestBundle = [NSBundle bundleForClass:self.class];
    NSString *jsonPath = [unitTestBundle pathForResource:@"places_example" ofType:@"json"];
    self.jsonData = [NSData dataWithContentsOfFile:jsonPath];
}

- (void)tearDown
{
    self.placesService = nil;    
    self.jsonData = nil;
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
    
    STAssertEqualObjects([[self.placesService request] URL], url, @"Request should find nearby places using the Google places API.");
    [self.placesService cancelRequest];
}

- (void)testConnectionDidReceiveResponseWithError
{
    NSError *error404 = [NSError errorWithDomain:GooglePlacesRequestErrorDomain code:404 userInfo:nil];
    
    // Expect a mock delegate to be called with the error.
    id mockPlacesDelegate = [OCMockObject mockForProtocol:@protocol(GooglePlacesServiceDelegate)];
    [[mockPlacesDelegate expect] placesRequestFailedWithError:error404];
    
    [self.placesService setDelegate:mockPlacesDelegate];

    // Request -> 404 Response
    [self.placesService requestPlacesWithLat:44.0
                                         lon:-93.0
                                      radius:10
                                     keyword:@"test"];
    [self.placesService connection:nil didReceiveResponse:self.failedResponse];

    [mockPlacesDelegate verify];
}

- (void)testConnectionFailedWithError
{
    NSError *fakeError = [NSError errorWithDomain:@"FakeConnectionErrorDomain" code:42 userInfo:nil];
    
    // Expect a mock delegate to be called with an error.
    id mockPlacesDelegate = [OCMockObject mockForProtocol:@protocol(GooglePlacesServiceDelegate)];
    [[mockPlacesDelegate expect] placesRequestFailedWithError:fakeError];
    
    [self.placesService setDelegate:mockPlacesDelegate];
    
    // Request -> Failed
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    [self.placesService connection:nil didFailWithError:fakeError];
    
    [mockPlacesDelegate verify];
}

- (void)testConnectionDidReceiveResponse
{
    // Nice mocks do not fail when unexpected methods are called.
    id mockPlacesDelegate = [OCMockObject niceMockForProtocol:@protocol(GooglePlacesServiceDelegate)];
    [self.placesService setDelegate:mockPlacesDelegate];
    
    // But they can be used to ensure that unwanted calls are rejected.  Here, we reject any errors.
    [[mockPlacesDelegate reject] placesRequestFailedWithError:OCMOCK_ANY];
    
    // A successful response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Request -> Response
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];    
    [self.placesService connection:nil didReceiveResponse:response];
    
    STAssertEquals([self.placesService responseData].length, 0U, @"Response data should be empty.");
    
    [mockPlacesDelegate verify];
}

- (void)testConnectionDidFinishLoading
{
    // Create a semaphore that will be signaled when the call is made.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0L);
    
    id mockPlacesDelegate = [OCMockObject mockForProtocol:@protocol(GooglePlacesServiceDelegate)];

    // We expect 
    [[[mockPlacesDelegate expect]
      andDo:^(NSInvocation *invocation)
    {
        // When invoked, signal the semaphore to continue execution.
        dispatch_semaphore_signal(sema);        
    }]
     placesRequestCompletedWithResults:[OCMArg checkWithBlock:^BOOL(id parameter)
    {
        // Make sure that we received all 4 results.
        NSArray *results = parameter;
        return results.count == 4;
    }]];
    
    [self.placesService setDelegate:mockPlacesDelegate];
    
    // A successful response.
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Request -> Response -> Data -> Finish
    [self.placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
    [self.placesService connection:nil didReceiveResponse:response];
    [self.placesService connection:nil didReceiveData:self.jsonData];
    [self.placesService connectionDidFinishLoading:nil];
    
    // Wait up to 5 seconds for the call to be made.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    dispatch_semaphore_wait(sema, popTime);
    dispatch_release(sema);
    
    [mockPlacesDelegate verify];
}



@end
