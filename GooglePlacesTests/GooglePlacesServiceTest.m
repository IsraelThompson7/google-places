#import "GooglePlacesServiceTest.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"
#import "GooglePlacesResult.h"
#import "MockGooglePlacesServiceDelegate.h"
#import "NoConnectionGooglePlacesService.h"

@interface GooglePlacesServiceTest ()

/// The places service to test.
///
@property (nonatomic, strong) GooglePlacesService *service;

/// A successful response with response code 200.
///
@property (nonatomic, strong) NSHTTPURLResponse *success;

/// A failed response with response code 404.
///
@property (nonatomic, strong) NSHTTPURLResponse *notFound;

@end

@implementation GooglePlacesServiceTest

#pragma mark - Setup and teardown methods

- (void)setUp
{
    // A NoConnectionGooglePlacesService won't actually make a connection.
    self.service = [[NoConnectionGooglePlacesService alloc]
                    initWithAPIKey:@"testKey"];
    
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
    
    STAssertEqualObjects([self.service.request URL], url,
                         @"Request should create a proper URL request.");
}

- (void)testConnectionFailedWithError
{
    NSError *error = [NSError errorWithDomain:@"FakeConnection"
                                         code:1234
                                     userInfo:nil];
    
    id delegate = [[MockGooglePlacesServiceDelegate alloc] init];
    self.service.delegate = delegate;
    
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didFailWithError:error];
    
    STAssertEquals([delegate lastError], error,
                   @"Failed connections should fail with an error.");
}

- (void)testConnectionDidReceiveResponse
{
    id delegate = [[MockGooglePlacesServiceDelegate alloc] init];
    self.service.delegate = delegate;

    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.success];
    
    STAssertNil(self.service.connection,
                @"Should not have a connnection.");
    STAssertEquals(self.service.responseData.length, 0U,
                   @"Response data should be empty.");
    STAssertNil([delegate lastError],
                @"200 response should not generate error.");
}

- (void)testConnectionDidReceiveResponseWithError
{
    id delegate = [[MockGooglePlacesServiceDelegate alloc] init];
    self.service.delegate = delegate;

    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.notFound];
    
    STAssertNotNil([delegate lastError],
                   @"Request should fail with an error.");
    STAssertEquals([delegate lastError].code, 404,
                   @"Request should fail with a 404.");
}

- (void)testConnectionDidFinishLoading
{
    // Load some sample json from the bundle.
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *path = [bundle pathForResource:@"places_example"
                                      ofType:@"json"];
    NSData *json = [NSData dataWithContentsOfFile:path];

    // Setup the delegate and fake a response, sending the data.
    id delegate = [[MockGooglePlacesServiceDelegate alloc] init];
    self.service.delegate = delegate;

    // Make the request...
    [self.service requestPlacesWithLat:44.0
                                   lon:-93.0
                                radius:10
                               keyword:@"test"];
    [self.service connection:nil didReceiveResponse:self.success];
    [self.service connection:nil didReceiveData:json];
    [self.service connectionDidFinishLoading:nil];
    
    // ...and wait for it to finish.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0L);
    [delegate waitUntilRequestCompletes:sema];
    dispatch_release(sema);
    
    // Now we can check the results.
    STAssertNotNil([delegate lastResults],
                   @"Finished request should have results.");
    STAssertEquals([delegate lastResults].count, 4U,
                   @"Should have received 4 places.");
}

@end
