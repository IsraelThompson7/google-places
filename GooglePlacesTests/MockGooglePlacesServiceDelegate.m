#import "MockGooglePlacesServiceDelegate.h"

@implementation MockGooglePlacesServiceDelegate
{
    dispatch_semaphore_t _sema;
}

- (void)waitUntilRequestCompletes:(dispatch_semaphore_t)sema
{
    _sema = sema;
    
    dispatch_retain(_sema);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)placesRequestCompletedWithResults:(NSArray *)results
{
    _lastResults = results;
    
    if (_sema)
    {
        dispatch_semaphore_signal(_sema);
        dispatch_release(_sema);
    }
}

- (void)placesRequestFailedWithError:(NSError *)error
{
    _lastError = error;
    
    if (_sema)
    {
        dispatch_semaphore_signal(_sema);
        dispatch_release(_sema);
    }
}

@end
