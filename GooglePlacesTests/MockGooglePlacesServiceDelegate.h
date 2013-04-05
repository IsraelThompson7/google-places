#import <Foundation/Foundation.h>
#import "GooglePlacesServiceDelegate.h"

@interface MockGooglePlacesServiceDelegate : NSObject<GooglePlacesServiceDelegate>

@property (nonatomic, readonly) NSArray *lastResults;
@property (nonatomic, readonly) NSError *lastError;

- (void)waitUntilRequestCompletes:(dispatch_semaphore_t)sema;

@end
