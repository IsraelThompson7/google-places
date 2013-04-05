@interface GooglePlacesService ()

/// The key used to identify this client to the Google's places API.
///
@property (nonatomic,strong) NSString *apiKey;

/// The connection to the URL specified once the request is started.
///
@property (nonatomic,strong) NSURLConnection *connection;

/// The request that contains the URL, cache policy and timeout values.
///
@property (nonatomic,strong) NSURLRequest *request;

/// The buffer that stores bytes read from the connection as they arrive.
///
@property (nonatomic,strong) NSMutableData *responseData;

/// Starts the request immediately.
///
- (void)startRequest;

@end
