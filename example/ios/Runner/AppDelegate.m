#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <MocaSDK//MOCA.h>
#import <MocaSDK//MOCAConfig.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
