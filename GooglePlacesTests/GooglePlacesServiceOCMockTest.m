#import "GooglePlacesServiceOCMockTest.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"
#import "GooglePlacesServiceDelegate.h"
#import "GooglePlacesResult.h"
#import <OCMock/OCMock.h>

@interface GooglePlacesServiceOCMockTest ()

/// The places service to test.
///
@property (nonatomic, strong) id service;

/// A successful response with response code 200.
///
@property (nonatomic, strong) NSHTTPURLResponse *success;

/// A failed response with response code 404.
///
@property (nonatomic, strong) NSHTTPURLResponse *notFound;

@end

@implementation GooglePlacesServiceOCMockTest

#pragma mark - Setup and teardown methods

- (void)setUp
{
    // The service we'll be testing.
    GooglePlacesService *placesService = [[GooglePlacesService alloc]
                                          initWithAPIKey:@"testKey"];
    
    // Create a partial mock that wraps the real service
    // instead of a subclass.  Just stub startRequest.
    self.service = [OCMockObject partialMockForObject:placesService];
    [[self.service stub] startRequest];
    
    // A successful response - 200 OK
    self.success = [[NSHTTPURLResponse alloc] initWithURL:nil
                                               statusCode:200
                                              HTTPVersion:nil
                                             headerFields:nil];
    
    // A failed response - 404 Not Found
    self.notFound = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                statusCode:404
                                               HTTPVersion:nil
                                              headerFields:nil];
}

- (void)tearDown
{
    [self.service cancelRequest];
    self.service = nil;
}

#pragma mark - Test methods

- (void)testRequestCreatesURLRequest
{
    NSURL *url = [NSURL URLWithString:@"https://maps.googleapis.com"
                  "/maps/api/place/search/json?key=testKey"
                  "&location=44.0000000,-93.0000000&radius=10"
                  "&keyword=test&sensor=true"];
    
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    
    STAssertEqualObjects([[self.service request] URL], url,
                         @"Request should create a proper URL request.");
}

- (void)testConnectionFailedWithError
{    
    // Creates a mock delegate.  No separate class required.
    id delegate = [OCMockObject mockForProtocol:
                   @protocol(GooglePlacesServiceDelegate)];
    [self.service setDelegate:delegate];

    NSError *error = [NSError errorWithDomain:@"FakeDomain"
                                         code:42
                                     userInfo:nil];

    // placesRequestFailedWithError: *must* be called with error.
    [[delegate expect] placesRequestFailedWithError:error];
    
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didFailWithError:error];
    
    [delegate verify];
}

- (void)testConnectionDidReceiveResponseWithError
{
    // Creates a mock delegate.  No separate class required.
    id delegate = [OCMockObject mockForProtocol:
                   @protocol(GooglePlacesServiceDelegate)];
    [self.service setDelegate:delegate];

    NSError *error404 = [NSError errorWithDomain:GooglePlacesServiceDomain
                                            code:404
                                        userInfo:nil];

    // placesRequestFailedWithError: *must* be called with error404.
    [[delegate expect] placesRequestFailedWithError:error404];
    
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.notFound];

    [delegate verify];
}

- (void)testConnectionDidReceiveResponse
{
    // Nice mocks don't fail when unexpected methods are called.
    id delegate = [OCMockObject niceMockForProtocol:
                   @protocol(GooglePlacesServiceDelegate)];
    [self.service setDelegate:delegate];

    // But they can be used to reject unwanted calls.
    [[delegate reject] placesRequestFailedWithError:OCMOCK_ANY];

    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.success];
    
    STAssertEquals([self.service responseData].length, 0U,
                   @"Response data should be empty.");
    
    [delegate verify];
}

- (void)testConnectionDidFinishLoading
{
    // Load an example json from the test bundle.
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *path = [bundle pathForResource:@"places_example"
                                      ofType:@"json"];
    NSData *json = [NSData dataWithContentsOfFile:path];
    
    // Creates a mock delegate.  No separate class required.
    id delegate = [OCMockObject mockForProtocol:
                             @protocol(GooglePlacesServiceDelegate)];
    [self.service setDelegate:delegate];
    
    // Create a semaphore that to wait for later.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0L);
    
    // When placesRequestCompletedWithResults is called, the semaphore
    // is signaled.
    [[[delegate expect] andDo:^(NSInvocation *invocation) {
        dispatch_semaphore_signal(sema);
    }] placesRequestCompletedWithResults:[OCMArg checkWithBlock:^BOOL(id parameter) {
        NSArray *results = parameter;
        return results.count == 4;        
    }]];
    
    // Make the request...
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.success];
    [self.service connection:nil didReceiveData:json];
    [self.service connectionDidFinishLoading:nil];
    
    // ...and wait for it to finish.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    dispatch_semaphore_wait(sema, popTime);
    dispatch_release(sema);
    
    // Now its OK to verify.
    [delegate verify];
}



@end
