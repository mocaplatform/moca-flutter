#import "MocaFlutterPlugin.h"
#import <MocaSDK/MOCA.h>
#import <MocaSDK/MOCAConfig.h>
#import <MocaSDK/MOCAInstance.h>
#import <MocaSDK/MOCAUser.h>
#import <MocaSDK/MOCARegion.h>
#import <MocaSDK/MOCAPlace.h>
#import <MocaSDK/MOCABeacon.h>
#import <MocaSDK/MOCARegionGroup.h>
#import <MocaSDK/MOCAExperience.h>
#import <MocaSDK/MOCACustomActionHandler.h>

@interface MocaFlutterPlugin() <UIApplicationDelegate,
    PlaceEventsObserver,
    BeaconEventsObserver,
    RegionGroupEventsObserver,
    MOCACustomActionHandler
>

@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) FlutterMethodChannel *backgroundChannel;
@property (strong, nonatomic) FlutterEngine *sBackgroundFlutterEngine;
@property (strong, nonatomic) CLLocationManager * locationManager;
@property (nonatomic) BOOL _initialized;

@end

@implementation MocaFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    MocaFlutterPlugin *instance = [[MocaFlutterPlugin alloc] init];
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"moca_flutter" binaryMessenger:[registrar messenger]];
    instance.channel = channel;
    // register as UIApplicationDelegate delegate
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
    
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self._initialized = NO;
    self.locationManager = [[CLLocationManager alloc] init];
    return self;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self autoInitializeSDK];
    return YES;
}


- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    if (MOCA.initialized && [MOCA isMocaNotification:notification]) {
        [MOCA userNotificationCenter:center
             willPresentNotification:notification
               withCompletionHandler:completionHandler];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
        didReceiveNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(void))completionHandler {
    
    if (MOCA.initialized && [MOCA isMocaNotification:notification]) {
        [MOCA userNotificationCenter:center didReceiveNotification:notification withCompletionHandler:completionHandler];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    if (MOCA.initialized && [MOCA isMocaNotification:response]) {
        [MOCA userNotificationCenter:center
      didReceiveNotificationResponse:response
               withCompletionHandler:completionHandler];
    }
}

- (void)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (MOCA.initialized && [MOCA isMocaNotification:userInfo]) {
        [MOCA handleRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

- (void)  application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"deviceToken: %@", deviceToken);
    if ([MOCA initialized]) {
        [MOCA registerDeviceToken:deviceToken];
    }
}

#pragma mark MocaFlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        if ([@"initializeSDK" isEqualToString:call.method]) {
            [self initializeSDK:call withResult:result];
        } else if ([@"registerBackgroundTask" isEqualToString:call.method]) {
            [self registerBackgroundTask:call withResult:result];
        } else if ([@"setLogLevel" isEqualToString:call.method]) {
            [self setLogLevel:call withResult:result];
        } else if ([@"initialized" isEqualToString:call.method]) {
            [self initialized:result];
        } else if ([@"getVersion" isEqualToString:call.method]) {
            [self getVersion:result];
        } else if ([@"getInstanceId" isEqualToString:call.method]) {
            [self getInstanceId:result];
        } else if ([@"getLogLevel" isEqualToString:call.method]) {
            [self getLogLevel:result];
        } else if ([@"getPermissionsStatus" isEqualToString:call.method]) {
            [self getPermissionsStatus:result];
        } else if ([@"geoTrackingEnabled" isEqualToString:call.method]) {
            [self geoTrackingEnabled:result];
        } else if ([@"setGeoTrackingEnabled" isEqualToString:call.method]) {
            [self setGeoTrackingEnabled:call withResult:result];
        } else if ([@"setUserId" isEqualToString:call.method]) {
            [self setUserId:call withResult:result];
        } else if ([@"getUserId" isEqualToString:call.method]) {
            [self getUserId:result];
        } else if ([@"eventTrackingEnabled" isEqualToString:call.method]) {
            [self eventTrackingEnabled:result];
        } else if ([@"setEventTrackingEnabled" isEqualToString:call.method]) {
            [self setEventTrackingEnabled:call withResult:result];
        } else if ([@"flushEvents" isEqualToString:call.method]) {
            [self flushEvents:call withResult:result];
        } else if ([@"getQueuedEvents" isEqualToString:call.method]) {
            [self getQueuedEvents:call withResult:result];
        } else if ([@"track" isEqualToString:call.method]) {
            [self track:call withResult:result];
        } else if ([@"trackViewed" isEqualToString:call.method]) {
            [self trackViewed:call withResult:result];
        } else if ([@"addToFavList" isEqualToString:call.method]) {
            [self addToFavList:call withResult:result];
        } else if ([@"clearFavList" isEqualToString:call.method]) {
            [self clearFavList:call withResult:result];
        } else if ([@"removeFromFavList" isEqualToString:call.method]) {
            [self removeFromFavList:call withResult:result];
        } else if ([@"addToWishList" isEqualToString:call.method]) {
            [self addToWishList:call withResult:result];
        } else if ([@"removeFromWishList" isEqualToString:call.method]) {
            [self removeFromWishList:call withResult:result];
        } else if ([@"clearWishList" isEqualToString:call.method]) {
            [self clearWishList:call withResult:result];
        } else if ([@"addToCart" isEqualToString:call.method]) {
            [self addToCart:call withResult:result];
        } else if ([@"updateCart" isEqualToString:call.method]) {
            [self updateCart:call withResult:result];
        } else if ([@"removeFromCart" isEqualToString:call.method]) {
            [self removeFromCart:call withResult:result];
        } else if ([@"clearCart" isEqualToString:call.method]) {
            [self clearCart:call withResult:result];
        } else if ([@"beginCheckout" isEqualToString:call.method]) {
            [self beginCheckout:call withResult:result];
        } else if ([@"completeCheckout" isEqualToString:call.method]) {
            [self completeCheckout:call withResult:result];
        } else if ([@"trackPurchased" isEqualToString:call.method]) {
            [self trackPurchased:call withResult:result];
        } else if ([@"trackShared" isEqualToString:call.method]) {
            [self trackShared:call withResult:result];
        } else if ([@"trackScreen" isEqualToString:call.method]) {
            [self trackScreen:call withResult:result];
        } else if ([@"getLastKnownLocation" isEqualToString:call.method]) {
            [self getLastKnownLocation:call withResult:result];
        } else if ([@"addTag" isEqualToString:call.method]) {
            [self addTag:call withResult:result];
        } else if ([@"getTags" isEqualToString:call.method]) {
            [self getTags:call withResult:result];
        } else if ([@"containsTag" isEqualToString:call.method]) {
            [self containsTag:call withResult:result];
        } else if ([@"getTagValue" isEqualToString:call.method]) {
            [self getTagValue:call withResult:result];
        } else if ([@"setRemotePushToken" isEqualToString:call.method]) {
            [self setRemotePushToken:call withResult:result];
        } else if ([@"setProperty" isEqualToString:call.method]) {
            [self setProperty:call withResult:result];
        } else if ([@"setProperties" isEqualToString:call.method]) {
            [self setProperties:call withResult:result];
        } else if ([@"getProperty" isEqualToString:call.method]) {
            [self getProperty:call withResult:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    } @catch (NSException *exception) {
        result([FlutterError errorWithCode:@"EXCEPTION"
                                   message:exception.reason
                                   details:exception.userInfo]);
    }
}

- (BOOL)autoInitializeSDK {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *appKey = [defaults objectForKey:@"MOCA_APP_KEY"];
    NSString *appSecret = [defaults objectForKey:@"MOCA_APP_SECRET"];
    if (appKey && appSecret) {
        [self performInitSDK:appKey withSecret:appSecret];
    }
    return self._initialized;
}

- (void)initializeSDK:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    // Ensure that the arguments are provided as a dictionary.
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Invalid arguments: expected a dictionary."
                                   details:nil]);
        return;
    }
    NSDictionary *argsDict = call.arguments;
    NSString *appKey = argsDict[@"appKey"];
    NSString *appSecret = argsDict[@"appSecret"];
    
    // Validate that both appKey and appSecret are non-empty strings.
    if (![appKey isKindOfClass:[NSString class]] || appKey.length == 0 ||
        ![appSecret isKindOfClass:[NSString class]] || appSecret.length == 0) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Invalid appKey and/or appSecret provided."
                                   details:@"Both appKey and appSecret must be non-empty strings." ]);
        return;
    }
    // Store the appKey and appSecret in NSUserDefaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:appKey forKey:@"MOCA_APP_KEY"];
    [defaults setObject:appSecret forKey:@"MOCA_APP_SECRET"];
    // Force immediate writing (optional, as iOS automatically synchronizes periodically).
    [defaults synchronize];
    [self performInitSDK:appKey withSecret:appSecret];
    result(@(YES));
}

- (void)performInitSDK:(NSString*)appKey withSecret:(NSString*)appSecret {
    
    if (!self._initialized) {
        // initialize SDK
        MOCAConfig * config = [MOCAConfig defaultConfigForAppKey:appKey andSecret:appSecret];
        self._initialized = [MOCA initializeSDK:config];
        [MOCA addRegionObserver:self];
        [MOCA setCustomActionHandler:self];
    }
}

#pragma mark - Plugin Method Implementations

- (void)initialized:(FlutterResult)result {
    BOOL isInitialized = MOCA.initialized;
    // Return the boolean value to Dart (wrapped as an NSNumber).
    result(@(isInitialized));
}

- (void)registerBackgroundTask:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    //
    // For this release, do not accept the task
    //
    result([FlutterError errorWithCode:@"MOCA_ERROR"
                               message:@"Method not supported in this release."
                               details:@"Please contact support@mocaplatform.com"]);
}

- (void)setLogLevel:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *logLevel = argsDict[@"logLevel"];
    if (!logLevel) {
        [MOCA setLogLevel:Off];
    } else if ([logLevel isEqualToString:@"debug"]) {
        [MOCA setLogLevel:Debug];
    } else if ([logLevel isEqualToString:@"info"]) {
        [MOCA setLogLevel:Info];
    } else if ([logLevel isEqualToString:@"warning"]) {
        [MOCA setLogLevel:Warning];
    } else if ([logLevel isEqualToString:@"error"]) {
        [MOCA setLogLevel:Error];
    } else {
        [MOCA setLogLevel:Off];
    }
    result(nil);
}

- (void)getVersion:(FlutterResult)result {
  // Retrieve version from the MOCA SDK.
  NSString *version = [MOCA sdKVersion];
  
  if (version != nil) {
    // Return the version string to Dart.
    result(version);
  } else {
    // Return an error if the version could not be retrieved.
    result([FlutterError errorWithCode:@"MOCA_ERROR"
                               message:@"Failed to retrieve version."
                               details:nil]);
  }
}

- (void)getUserId:(FlutterResult)result {
    MOCAUser *user = [MOCA currentUser];
    if (user != nil) {
        result(user.identifier);
    } else {
        // Return an error if the instance ID could not be retrieved.
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Failed to retrieve user ID."
                                   details:nil]);
    }
}

- (void)getInstanceId:(FlutterResult)result {
    MOCAInstance *instance = [MOCA currentInstance];
    if (instance != nil) {
        // Return the instance ID string to Dart.
        result(instance.identifier);
    } else {
        // Return an error if the instance ID could not be retrieved.
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Failed to retrieve instance ID."
                                   details:nil]);
    }
}

- (void)getLogLevel:(FlutterResult)result {
    // Retrieve log level from the MOCA SDK.
    MOCALogLevel logLevel = [MOCA logLevel];
    
    // Convert the enum value to an NSString.
    NSString *logLevelString;
    switch (logLevel) {
        case Off:
            logLevelString = @"off";
            break;
        case Error:
            logLevelString = @"error";
            break;
        case Warning:
            logLevelString = @"warn";
            break;
        case Info:
            logLevelString = @"info";
            break;
        case Debug:
            logLevelString = @"debug";
            break;
        case Trace:
            logLevelString = @"trace";
            break;
        default:
            logLevelString = @"unknown";
            break;
    }
    
    // Return the log level string to Dart.
    result(logLevelString);
}

- (void)getPermissionsStatus:(FlutterResult)result {
    if (!result) {
        return;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    NSString *statusStr;
    switch (status) {
        case kCLAuthorizationStatusDenied:
            statusStr = @"denied";
            break;
        case kCLAuthorizationStatusRestricted:
            statusStr = @"denied";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            statusStr = @"background";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusStr = @"foreground";
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusStr = @"not_determined";
            break;
        default:
            statusStr = @"denied";
            break;
    }
    result(statusStr);
}


// Geo Tracking Enabled (returns a BOOL wrapped as an NSNumber)
- (void)geoTrackingEnabled:(FlutterResult)result {
    // Assume [MOCA geoTrackingEnabled] returns a BOOL.
    BOOL enabled = [MOCA geoTrackingEnabled];
    result(@(enabled));
}

// Set Geo Tracking Enabled (expects an "enabled" key in the arguments)
- (void)setGeoTrackingEnabled:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    BOOL enabled = [args[@"enabled"] boolValue];
    [MOCA setGeoTrackingEnabled:enabled];
    result(nil);
}

- (void)setUserId:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *userId = argsDict[@"userId"];
    if (userId == nil) {
        MOCAUser * user = [MOCA currentUser];
        if (user != nil) {
            [user logout];
            result(@(YES));
        }
    } else {
        [[MOCA currentInstance] login:userId];
    }
    result(@(YES));
}

- (void)getUserId:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSString * userId = nil;
    if (MOCA.initialized) {
        MOCAUser * user = MOCA.currentUser;
        if (user != nil) {
            userId = user.identifier;
        }
    }
    result(userId);
}

// Event Tracking Enabled
- (void)eventTrackingEnabled:(FlutterResult)result {
    BOOL enabled = [MOCA eventTrackingEnabled];
    result(@(enabled));
}

// Set Event Tracking Enabled
- (void)setEventTrackingEnabled:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    BOOL enabled = [args[@"enabled"] boolValue];
    [MOCA setEventTrackingEnabled:enabled];
    result(@(YES));
}

// Flush Events
- (void)flushEvents:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA flushEvents];
    result(@(YES));
}

// Get Queued Events (returns an integer count)
- (void)getQueuedEvents:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    long count = [MOCA getQueuedEvents];
    result(@(count));
}

- (NSString *)requiredStringForKey:(NSString *)key inArgs:(NSDictionary *)args error:(FlutterError **)error {
    id value = args[key];
    if (value == nil || value == [NSNull null] ||
        ![value isKindOfClass:[NSString class]] ||
        [((NSString *)value) length] == 0) {
        if (error) {
            *error = [FlutterError errorWithCode:@"MOCA_ERROR"
                                         message:[NSString stringWithFormat:@"Invalid argument: '%@' is obligatory.", key]
                                         details:[NSString stringWithFormat:@"The '%@' parameter is required and must be a non-empty string.", key]];
        }
        return nil;
    }
    return (NSString *)value;
}

// Track Viewed Event
- (void)trackViewed:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    
    FlutterError *error = nil;
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    NSString *category = args[@"category"];
    BOOL recommended = [args[@"recommended"] boolValue];
    [MOCA trackViewed:item belongingTo:category wasRecommended:recommended];
    result(@(YES));
}

// Track a generic event
- (void)track:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    
    FlutterError *error = nil;
    NSString *verb = [self requiredStringForKey:@"verb" inArgs:args error:&error];
    if (!verb) {
        result(error);
        return;
    }
    NSString *item = args[@"item"];
    NSString *category = args[@"category"];
    id value = args[@"value"];
    [MOCA track:verb withItem:item belongingTo:category withValue:value];
    result(@(YES));
}

- (void)addToFavList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    BOOL success = [MOCA addToFavList:item];
    result(@(success));
}

- (void)removeFromFavList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    BOOL success = [MOCA removeFromFavList:item];
    result(@(success));
}

- (void)clearFavList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA clearFavList];
    result(@(YES));
}

- (void)addToWishList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    BOOL success = [MOCA addToWishList:item];
    result(@(success));
}

- (void)removeFromWishList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    BOOL success = [MOCA removeFromWishList:item];
    result(@(success));
}

- (void)clearWishList:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA clearWishList];
    result(@(YES));
}

- (void)clearCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA clearCart];
    result(@(YES));
}

- (void)addToCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    // Validate "item"
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    
    // Validate unitPrice (must be present)
    id unitPriceValue = args[@"unitPrice"];
    if (unitPriceValue == nil || unitPriceValue == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: unitPrice is obligatory."
                                   details:nil]);
        return;
    }
    double unitPrice = [unitPriceValue doubleValue];
    if (unitPrice < 0) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"unitPrice must be greater or equal to zero."
                                   details:nil]);
        return;
    }
    
    // Validate "currency"
    NSString *currency = [self requiredStringForKey:@"currency" inArgs:args error:&error];
    if (!currency) {
        result(error);
        return;
    }
    
    // Validate quantity
    id quantityValue = args[@"quantity"];
    if (quantityValue == nil || quantityValue == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: quantity is obligatory."
                                   details:nil]);
        return;
    }
    int quantity = [quantityValue intValue];
    if (quantity < 1) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Quantity must be positive integer."
                                   details:nil]);
        return;
    }
    
    // "category" is optional.
    NSString *category = args[@"category"];
    
    id<MOCAItem> cartItem = [MOCA createItem:item belongingTo:category withUnitPrice:unitPrice withCurrency:currency];
    [MOCA addToCart:cartItem withQuantity:quantity];
    result(@(YES));
}

- (void)updateCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    
    id quantityValue = args[@"quantity"];
    if (quantityValue == nil || quantityValue == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: quantity is obligatory."
                                   details:nil]);
        return;
    }
    int quantity = [quantityValue intValue];
    if (quantity < 1) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Quantity must be positive integer."
                                   details:nil]);
        return;
    }
    BOOL success = [MOCA updateCart:item withQuantity:quantity];
    result(@(success));
}

- (void)removeFromCart:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    
    BOOL success = [MOCA removeFromCart:item];
    result(@(success));
}

- (void)trackPurchased:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    
    // Optional category.
    NSString *category = args[@"category"];
    
    id unitPriceValue = args[@"unitPrice"];
    if (unitPriceValue == nil || unitPriceValue == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: unitPrice is obligatory."
                                   details:nil]);
        return;
    }
    double unitPrice = [unitPriceValue doubleValue];
    if (unitPrice < 0) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"unitPrice must be greater or equal to zero."
                                   details:nil]);
        return;
    }
    
    NSString *currency = [self requiredStringForKey:@"currency" inArgs:args error:&error];
    if (!currency) {
        result(error);
        return;
    }
    
    id quantityValue = args[@"quantity"];
    if (quantityValue == nil || quantityValue == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: quantity is obligatory."
                                   details:nil]);
        return;
    }
    int quantity = [quantityValue intValue];
    if (quantity < 1) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Quantity must be positive integer."
                                   details:nil]);
        return;
    }
    [MOCA trackPurchased:item belongingTo:category withUnitPrice:unitPrice withCurrency:currency withQuantity:quantity];
    result(@(YES));
}

- (void)beginCheckout:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA beginCheckout];
    result(@(YES));
}

- (void)completeCheckout:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [MOCA completeCheckout];
    result(@(YES));
}

- (void)getLastKnownLocation:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    CLLocation *location = [MOCA lastKnownLocation];
    if (location) {
        NSDictionary *locationDict = @{
            @"latitude": @(location.coordinate.latitude),
            @"longitude": @(location.coordinate.longitude),
            @"altitude": @(location.altitude),
            @"accuracy": @(location.horizontalAccuracy),
            // Return the timestamp as seconds since 1970
            @"timestamp": @([location.timestamp timeIntervalSince1970])
        };
        result(locationDict);
    } else {
        result(nil);
    }
}

- (void)trackShared:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *item = [self requiredStringForKey:@"item" inArgs:args error:&error];
    if (!item) {
        result(error);
        return;
    }
    
    [MOCA trackShared:item];
    result(@(YES));
}

- (void)trackScreen:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *screenName = [self requiredStringForKey:@"screenName" inArgs:args error:&error];
    if (!screenName) {
        result(error);
        return;
    }
    
    [MOCA trackScreenFragment:screenName];
    result(@(YES));
}

- (void)getTags:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *tags = [MOCA getTags];
    if (tags) {
        result(tags);
    } else {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Could not retrieve tags."
                                   details:nil]);
    }
}

- (void)addTag:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *tag = [self requiredStringForKey:@"tag" inArgs:args error:&error];
    if (!tag) {
        result(error);
        return;
    }
    
    // "value" is optional.
    NSString *value = args[@"value"];
    [MOCA addTag:tag withValue:value];
    result(@(YES));
}

- (void)containsTag:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *tag = [self requiredStringForKey:@"tag" inArgs:args error:&error];
    if (!tag) {
        result(error);
        return;
    }
    
    BOOL contains = [MOCA containsTag:tag];
    result(@(contains));
}

- (void)getTagValue:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *tag = [self requiredStringForKey:@"tag" inArgs:args error:&error];
    if (!tag) {
        result(error);
        return;
    }
    // TODO FIX ME!
    result(nil);
}

- (NSData *)dataFromDeviceTokenString:(NSString *)tokenString {
    // Check for nil or empty string.
    if (!tokenString || tokenString.length == 0) {
        return nil;
    }
    
    // The hex string should have an even number of characters.
    if (tokenString.length % 2 != 0) {
        return nil;
    }
    
    NSMutableData *data = [NSMutableData dataWithCapacity:tokenString.length / 2];
    
    for (NSUInteger i = 0; i < tokenString.length; i += 2) {
        // Extract two characters (one byte) at a time.
        NSString *hexByte = [tokenString substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        NSScanner *scanner = [NSScanner scannerWithString:hexByte];
        
        // Scan the hex value.
        if (![scanner scanHexInt:&byteValue]) {
            return nil; // Invalid hex digit encountered.
        }
        
        uint8_t byte = (uint8_t)byteValue;
        [data appendBytes:&byte length:1];
    }
    
    return [data copy];
}


- (void)setRemotePushToken:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *token = [self requiredStringForKey:@"token" inArgs:args error:&error];
    if (!token) {
        result(error);
        return;
    }
    NSData * data = [self dataFromDeviceTokenString:token];
    [MOCA registerDeviceToken:data];
    result(@(YES));
}

- (void)setProperty:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *key = [self requiredStringForKey:@"key" inArgs:args error:&error];
    if (!key) {
        result(error);
        return;
    }
    
    id value = args[@"value"];
    if (value == nil || value == [NSNull null]) {
        result([FlutterError errorWithCode:@"MOCA_ERROR"
                                   message:@"Missing parameter: value is obligatory."
                                   details:nil]);
        return;
    }
    MOCAUser * user = [MOCA currentUser];
    if (user != nil) {
        [user setValue:value forProperty:key];
    } else {
        MOCAInstance * instance = [MOCA currentInstance];
        [instance setValue:value forProperty:key];
    }
    result(@(YES));
}

- (void)setProperties:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *props = call.arguments;
    MOCAUser * user = [MOCA currentUser];
    if (user != nil) {
        [user setProperties:props];
    } else {
        [[MOCA currentInstance] setProperties:props];
    }
    result(@(YES));
}

- (void)getProperty:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    FlutterError *error = nil;
    
    NSString *key = [self requiredStringForKey:@"key" inArgs:args error:&error];
    if (!key) {
        result(error);
        return;
    }
    MOCAUser * user = [MOCA currentUser];
    if (user != nil) {
        id value = [user valueForProperty:key];
        result (value);
    } else {
        id value = [[MOCA currentInstance] valueForProperty:key];
        result (value);
    }
}


#pragma mark PlaceEventsObserver

- (NSArray *)placeToArgs:(MOCAPlace *)place {
    // Create a mutable dictionary to hold the properties.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    // Set the "name" property if available.
    dict[@"name"] = place.name;
    dict[@"id"] = place.identifier;
    
    // If the place has a geofence, add its details.
    CLCircularRegion *geofence = place.geofence;
    if (geofence) {
        // Assume radius is a double.
        dict[@"radius"] = @(geofence.radius);
        
        // Assume the geofence has a "center" property returning a CLLocationCoordinate2D.
        CLLocationCoordinate2D center = geofence.center;
        dict[@"latitude"] = @(center.latitude);
        dict[@"longitude"] = @(center.longitude);
    }
    
    // Wrap the dictionary in an array with an initial element (here, 0).
    NSArray *args = @[@0, dict];
    return args;
}

- (void)didEnterPlace:(MOCAPlace *)place {
    @try {
        // Convert the 'place' to an array of arguments.
        NSArray *args = [self placeToArgs:place];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onEnterGeofence" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (void)didExitPlace:(MOCAPlace *)place {
    @try {
        // Convert the 'place' to an array of arguments.
        NSArray *args = [self placeToArgs:place];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onExitGeofence" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (NSArray *)beaconToArgs:(MOCABeacon *)beacon {
    // Create a mutable dictionary to hold the properties.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"name"] = beacon.name;
    dict[@"id"] = beacon.identifier;
    
    // If the place has a geofence, add its details.
    CLLocation *location = beacon.location;
    if (location) {
        CLLocationCoordinate2D center = location.coordinate;
        dict[@"latitude"] = @(center.latitude);
        dict[@"longitude"] = @(center.longitude);
    }
    
    // Wrap the dictionary in an array with an initial element (here, 0).
    NSArray *args = @[@0, dict];
    return args;
}


- (void)didEnterBeacon:(MOCABeacon *)beacon {
    @try {
        // Convert the 'beacon' to an array of arguments.
        NSArray *args = [self beaconToArgs:beacon];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onEnterBeacon" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (void)didExitBeacon:(MOCABeacon *)beacon {
    @try {
        // Convert the 'beacon' to an array of arguments.
        NSArray *args = [self beaconToArgs:beacon];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onExitBeacon" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (void)didRangeBeacon:(MOCABeacon *)beacon withProximity:(CLProximity)proximity { 
    // ignore
}


- (NSArray *)groupToArgs:(MOCARegionGroup *)group {
    // Create a mutable dictionary to hold the properties.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@"name"] = group.name;
    dict[@"id"] = group.identifier;
    
    // Wrap the dictionary in an array with an initial element (here, 0).
    NSArray *args = @[@0, dict];
    return args;
}

- (void)didEnterRegionGroup:(MOCARegionGroup *)group {
    @try {
        // Convert the 'beacon' to an array of arguments.
        NSArray *args = [self groupToArgs:group];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onEnterRegionGroup" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (void)didExitRegionGroup:(MOCARegionGroup *)group {
    @try {
        // Convert the 'beacon' to an array of arguments.
        NSArray *args = [self groupToArgs:group];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onExitRegionGroup" arguments:args];
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

- (NSString *)observerId { 
    return @"MocaFlutterPlugin";
}

#pragma mark MOCACustomActionHandler

- (NSArray *)toCustomActionArgs:(MOCAExperience *)sender withAttribute:(NSString *)customAttribute {
    // Create a mutable dictionary to hold the values.
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // Set the "experience" key using the sender’s name.
    dict[@"experience"] = sender.name;
    dict[@"experienceId"] = sender.identifier;
    dict[@"campaignId"] = sender.campaignId;
    dict[@"campaign"] = sender.campaignName;

    // Set the custom attribute.
    if (customAttribute != nil) {
        dict[@"customAttribute"] = customAttribute;
    }
    
    // Wrap the dictionary in an array with a leading element (@0).
    NSArray *args = @[@0, dict];
    return args;
}

-(BOOL) performCustomAction:(MOCAExperience *) sender attribute:(NSString *) customAttribute {
    
    @try {
        // Convert the 'beacon' to an array of arguments.
        NSArray *args = [self toCustomActionArgs:sender withAttribute:customAttribute];
        
        // Ensure the call is performed on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel invokeMethod:@"onCustomAction" arguments:args];
        });
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception);
        return NO;
    }
    
}



@end
