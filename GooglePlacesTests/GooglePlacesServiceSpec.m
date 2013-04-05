#import "Kiwi.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"

SPEC_BEGIN(GooglePlacesServiceSpec)

describe(@"GooglePlacesService", ^{
    __block GooglePlacesService *placesService = nil;
        
    beforeEach(^{
        placesService = [[GooglePlacesService alloc] initWithAPIKey:@"testKey"];
        [placesService stub:@selector(startRequest)];
    });
        
    afterEach(^{
        [placesService cancelRequest];
    });
    
    context(@"when requesting places", ^{
        it(@"should create a proper URL request", ^{
            NSURL *url = [NSURL URLWithString:@"https://maps.googleapis.com/maps/api/place/search/json?"
             "key=testKey&location=44.0000000,-93.0000000&radius=10&keyword=test&sensor=true"];

            [placesService requestPlacesWithLat:44.0
                                            lon:-93.0
                                         radius:10
                                        keyword:@"test"];

            [[placesService.request.URL should] equal:url];
        });        
    });
    
    context(@"when receiving an error response", ^{
        it(@"should notify its delegate with an error", ^{            
            NSError *error404 = [NSError errorWithDomain:GooglePlacesRequestErrorDomain
                                                    code:404
                                                userInfo:nil];
            
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                                      statusCode:404
                                                                     HTTPVersion:nil
                                                                    headerFields:nil];
            id mockDelegate = [KWMock mockForProtocol:@protocol(GooglePlacesServiceDelegate)];
            [mockDelegate expect:@selector(placesRequestFailedWithError:) withArguments:error404];
            
            placesService.delegate = mockDelegate;
            
            [placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
            [placesService connection:nil didReceiveResponse:response];
        });
    });
    
    context(@"when a connection fails", ^{
        it(@"should notify its delegate with an error", ^{
            NSError *error = [NSError errorWithDomain:@"FakeConnectionError"
                                                 code:42
                                             userInfo:nil];

            id mockDelegate = [KWMock mockForProtocol:@protocol(GooglePlacesServiceDelegate)];
            [mockDelegate expect:@selector(placesRequestFailedWithError:) withArguments:error];
            
            placesService.delegate = mockDelegate;
            
            [placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
            [placesService connection:nil didFailWithError:error];
        });
    });
    
    context(@"when receiving a successful response", ^{
        __block NSHTTPURLResponse *successfulResponse;
        
        beforeEach(^{
            successfulResponse = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                             statusCode:200
                                                            HTTPVersion:nil
                                                           headerFields:nil];
            
        });
        
        it(@"should create an empty response data", ^{            
            [placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
            [placesService connection:nil didReceiveResponse:successfulResponse];

            [[placesService responseData] shouldNotBeNil];
            [[[placesService responseData] should] beEmpty];
            
        });
        
        context(@"when a connection finishes loading", ^{            
            it(@"should notify its delegate with results", ^{
                
                NSBundle *unitTestBundle = [NSBundle bundleForClass:self.class];
                NSString *jsonPath = [unitTestBundle pathForResource:@"places_example" ofType:@"json"];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];

                id mockDelegate = [KWMock mockForProtocol:@protocol(GooglePlacesServiceDelegate)];
                [[mockDelegate shouldEventually] receive:@selector(placesRequestCompletedWithResults:)];
                
                placesService.delegate = mockDelegate;                
                
                [placesService requestPlacesWithLat:44.0 lon:-93.0 radius:10 keyword:@"test"];
                [placesService connection:nil didReceiveResponse:successfulResponse];
                [placesService connection:nil didReceiveData:jsonData];
                [placesService connectionDidFinishLoading:nil];                
            });
        });
    });
});

SPEC_END