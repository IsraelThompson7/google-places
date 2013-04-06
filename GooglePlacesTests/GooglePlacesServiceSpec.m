#import "Kiwi.h"
#import "GooglePlacesService.h"
#import "GooglePlacesService_Private.h"

SPEC_BEGIN(GooglePlacesServiceSpec)

describe(@"GooglePlacesService", ^{
    __block GooglePlacesService *service = nil;
    
    beforeEach(^{
        // Stub startRequest method so there's no connection.
        service = [[GooglePlacesService alloc]
                   initWithAPIKey:@"testKey"];
        [service stub:@selector(startRequest)];
    });
    
    afterEach(^{
        [service cancelRequest];
    });
    
    it(@"should create a proper URL request", ^{
        NSURL *url = [NSURL URLWithString:
                      @"https://maps.googleapis.com"
                      "/maps/api/place/search/json?key=testKey"
                      "&location=44.0000000,-93.0000000"
                      "&radius=10&keyword=test&sensor=true"];
        
        [service requestPlacesWithLat:44.0
                                  lon:-93.0
                               radius:10
                              keyword:@"test"];
        
        [[service.request.URL should] equal:url];
    });
    
    it(@"should notify its delegate with an error", ^{
        id delegate = [KWMock mockForProtocol:
                       @protocol(GooglePlacesServiceDelegate)];
        service.delegate = delegate;
        
        NSError *error = [NSError errorWithDomain:@"FakeConnectionError"
                                             code:42
                                         userInfo:nil];
        [delegate expect:@selector(placesRequestFailedWithError:)
           withArguments:error];
        
        [service requestPlacesWithLat:44.0
                                  lon:-93.0
                               radius:10
                              keyword:@"test"];
        [service connection:nil didFailWithError:error];
    });
    
    context(@"when receiving an error response", ^{
        __block NSHTTPURLResponse *notFound;
        
        beforeEach(^{
            notFound = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                   statusCode:404
                                                  HTTPVersion:nil
                                                 headerFields:nil];
        });
        
        it(@"should notify its delegate with an error", ^{
            id delegate = [KWMock mockForProtocol:
                           @protocol(GooglePlacesServiceDelegate)];
            service.delegate = delegate;
            
            NSError *error404 = [NSError errorWithDomain:GooglePlacesServiceDomain
                                                    code:404
                                                userInfo:nil];
            
            [delegate expect:@selector(placesRequestFailedWithError:)
               withArguments:error404];
            
            [service requestPlacesWithLat:44.0
                                      lon:-93.0
                                   radius:10
                                  keyword:@"test"];
            [service connection:nil didReceiveResponse:notFound];
        });
    });
    
    context(@"when receiving a successful response", ^{
        __block NSHTTPURLResponse *success;
        
        beforeEach(^{
            success = [[NSHTTPURLResponse alloc] initWithURL:nil
                                                  statusCode:200
                                                 HTTPVersion:nil
                                                headerFields:nil];
        });
        
        it(@"should create an empty response data", ^{
            [service requestPlacesWithLat:44.0
                                      lon:-93.0
                                   radius:10
                                  keyword:@"test"];
            [service connection:nil didReceiveResponse:success];
            
            [[service responseData] shouldNotBeNil];
            [[[service responseData] should] beEmpty];
        });
        
        it(@"should not notify its delegate with an error", ^{
            id delegate = [KWMock mockForProtocol:
                           @protocol(GooglePlacesServiceDelegate)];
            service.delegate = delegate;
            
            [[delegate shouldNot] receive:@selector(placesRequestFailedWithError:)];
        });
        
        it(@"should notify its delegate with results", ^{
            NSBundle *bundle = [NSBundle bundleForClass:self.class];
            NSString *path = [bundle pathForResource:@"places_example"
                                              ofType:@"json"];
            NSData *json = [NSData dataWithContentsOfFile:path];
            
            id delegate = [KWMock mockForProtocol:
                           @protocol(GooglePlacesServiceDelegate)];
            service.delegate = delegate;
            
            // Waits for the block to return until the delegate is called.
            [[delegate shouldEventually]
             receive:@selector(placesRequestCompletedWithResults:)];
            
            [service requestPlacesWithLat:44.0
                                      lon:-93.0
                                   radius:10
                                  keyword:@"test"];
            [service connection:nil didReceiveResponse:success];
            [service connection:nil didReceiveData:json];
            [service connectionDidFinishLoading:nil];
        });
    });
});

SPEC_END