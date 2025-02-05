///
///  moca_flutter.dart
///
///  Moca Flutter Plugin
///
///  This module is part of Moca platform.
///
///  Copyright (c) 2024 Moca Technologies.
///  All rights reserved.
///
///  All rights to this software by Moca Technologies are owned by 
///  Moca Technologies and only limited rights are provided by the 
/// licensing or contract under which this software is provided.
///
///  Any use of the software for any commercial purpose without
///  the written permission of Moca Technologies is prohibited.
///  You may not alter, modify, or in any way change the appearance
///  and copyright notices on the software. You may not reverse compile
///  the software or publish any protected intellectual property embedded
///  in the software. You may not distribute, sell or make copies of
///  the software available to any entities without the explicit written
///  permission of Moca Technologies.
///

import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

/// A generic result wrapper that allows the caller to easily check
/// if the call succeeded and extract either the value or the error message.
class MocaResult<T> {
  final T? data;
  final String? error;

  bool get isSuccess => error == null;

  MocaResult.success(this.data) : error = null;
  MocaResult.failure(this.error) : data = null;
}

/// A generic background event
class MocaBackgroundEvent {
  final String name;
  final dynamic event;

  MocaBackgroundEvent(this.name, this.event);
  
  @override
  String toString() {
    return '[MocaBackgroundEvent name: $name, event: $event]';
  }
}

/// The background callback dispatcher that is registered when your
/// plugin is invoked in the background (for example, from a background isolate).
/// Reference: https://medium.com/flutter/executing-dart-in-the-background-with-flutter-plugins-and-geofencing-2b3e40a1a124
@pragma('vm:entry-point')
void callbackDispatcher() {
  const MethodChannel _backgroundChannel =
      MethodChannel('moca_flutter_background');
  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    try {
      final args = call.arguments;
      final CallbackHandle handle = CallbackHandle.fromRawHandle(args[0]);
      final Function? callback = PluginUtilities.getCallbackFromHandle(handle);
      final Map res = args[1];
      // Call the provided background callback with the data.
      callback?.call(res);
    } catch (e, stackTrace) {
      developer.log("Error in background callback: $e",
          name: 'Moca', stackTrace: stackTrace);
    }
  });
}

/// Callback type definitions.
typedef MocaErrorCallback = void Function(Map<dynamic, dynamic> errorEvent);
typedef MocaRegionCallback = void Function(String verb, Map<dynamic, dynamic> region);
typedef MocaActionCallback = void Function(String action, Map<dynamic, dynamic> args);
typedef MocaNavigatorCallback = bool Function(String url);
typedef MocaBackgroundCallback = void Function(Map<dynamic, dynamic> event);

/// Observer to track Flutter screen transitions and call Moca.trackScreen.
class MocaRouteObserver extends NavigatorObserver {
  static final MocaRouteObserver instance = MocaRouteObserver._internal();

  MocaRouteObserver._internal();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (Moca._isSdkInitialized) {
      //print('screenPush: $route');
      if (route.settings.name != null) {
        // , previousRoute?.settings.name
        Moca.trackScreen(route.settings.name!);
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (Moca._isSdkInitialized) {
      //print('screenPop: $route');
      if (previousRoute?.settings.name != null) {
        // , previousRoute?.settings.name
        Moca.trackScreen(previousRoute!.settings.name!);
      }
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (Moca._isSdkInitialized) {
      //print('screenReplace: $newRoute');
      if (newRoute?.settings.name != null) {
        Moca.trackScreen(newRoute!.settings.name!);
      }
    }
  }
}

class Moca {
  static const MethodChannel _channel = MethodChannel('moca_flutter');

  // Foreground callbacks
  static MocaRegionCallback? foregroundGeofenceCallback;
  static MocaRegionCallback? foregroundBeaconCallback;
  static MocaRegionCallback? foregroundRegionGroupCallback;
  static MocaActionCallback? foregroundActionCallback;
  static MocaNavigatorCallback? foregroundNavigatorCallback;
  static MocaErrorCallback? foregroundErrorCallback;
  static bool _isSdkInitialized = false;
  static String? _pendingFirstScreen;

  /// A helper method that centralizes error handling. It invokes the method on
  /// the platform channel and catches common exceptions, logging them and
  /// returning a MocaResult that contains either the value or an error message.
  static Future<MocaResult<T>> _invokeMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    try {
      final T? result = await _channel.invokeMethod<T>(method, arguments);
      return MocaResult.success(result);
    } on PlatformException catch (e, stackTrace) {
      developer.log("PlatformException in $method: ${e.message}",
          name: 'Moca', stackTrace: stackTrace);
      return MocaResult.failure("Platform error: ${e.message}");
    } on MissingPluginException catch (e, stackTrace) {
      developer.log("MissingPluginException in $method: ${e.message}",
          name: 'Moca', stackTrace: stackTrace);
      return MocaResult.failure("Missing plugin: ${e.message}");
    } catch (e, stackTrace) {
      developer.log("Unknown error in $method: $e",
          name: 'Moca', stackTrace: stackTrace);
      return MocaResult.failure("Unknown error: $e");
    }
  }

  /// Initializes the SDK. On success, it also registers the foreground callback handler.
  static Future<MocaResult<void>> initializeSDK(
      String appKey, String appSecret) async {
    final result = await _invokeMethod<void>(
      'initializeSDK',
      {'appKey': appKey, 'appSecret': appSecret},
    );
    if (result.isSuccess) {
      // Once the SDK is initialized, set up the foreground callback handler.
      _channel.setMethodCallHandler(_handleMethodCall);
      _isSdkInitialized = true;
      // Make sure first screen displayed before initializeSDK is tracked.
      if (_pendingFirstScreen != null) {
        trackScreen(_pendingFirstScreen!);
        _pendingFirstScreen = null;
      }
    }
    return result;
  }

  static NavigatorObserver getNavigatorObserver() {
    return MocaRouteObserver.instance;
  }

  /// Register a global Dart function that receives all events from MOCA SDK running in background 
  /// while Dart UI is terminated ("headless" state).
  ///
  /// __WARNINGS:__ 
  /// Callback function **must** be defined as a distinct function, not an anonymous callback.
  /// You **must** place `registerBackgroundCallback` in your `main.dart`.  
  /// Do **not** place it in your application components.
  ///
  static Future<MocaResult<bool?>> registerBackgroundCallback(void Function(MocaBackgroundEvent) callback) async {
    // Two callbacks:  the provided background callback + plugin own background callback dispatcher.
    List<int> args = [
      PluginUtilities.getCallbackHandle(callbackDispatcher)!.toRawHandle(),
      PluginUtilities.getCallbackHandle(callback)!.toRawHandle()
    ];
    return await _invokeMethod<bool>('registerBackgroundTask');
  }  

  /// Tracks the current screen name by invoking the native method trackScreen.
  static Future<MocaResult<bool?>> trackScreen(String screenName) async {
    if (!_isSdkInitialized) {
      _pendingFirstScreen = screenName;
      return MocaResult.success(true);
    } 
    return await _invokeMethod<bool>('trackScreen', {
      'screenName': screenName
    });
  }

  /// This is the foreground method call handler. It is only invoked when the app
  /// is in the foreground. If the app is in the background, the handler logs the event
  /// and skips calling the foreground callbacks (background events are handled
  /// by the [callbackDispatcher]).
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    // Check the app lifecycle state: if the app is not resumed (i.e. in background),
    // skip the foreground callback.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      developer.log("App in background. Skipping foreground callback for ${call.method}",
          name: 'Moca');
      return null;
    }

    final args = call.arguments;
    final props = args[1] as Map<dynamic, dynamic>;
    switch (call.method) {
      case 'onEnterGeofence':
        foregroundGeofenceCallback?.call('enter', props);
        break;
      case 'onExitGeofence':
        foregroundGeofenceCallback?.call('exit', props);
        break;
      case 'onEnterBeacon':
        foregroundBeaconCallback?.call('enter', props);
        break;
      case 'onExitBeacon':
        foregroundBeaconCallback?.call('exit', props);
        break;
      case 'onEnterRegionGroup':
        foregroundRegionGroupCallback?.call('enter', props);
        break;
      case 'onExitRegionGroup':
        foregroundRegionGroupCallback?.call('exit', props);
        break;
      case 'onCustomAction':
        foregroundActionCallback?.call('custom', props);
        break;
      case 'onGotoUri':
        final String uri = args[0] as String;
        if (foregroundNavigatorCallback != null) {
           // The navigator callback should return true if the URL is handled,
           // or false if further processing is needed by the native SDK.
           final bool handled = foregroundNavigatorCallback!(uri);
           return handled;
        }
        return false;
      case 'error':
        foregroundErrorCallback?.call(props);
        break;
      default:
        developer.log("Unhandled method: ${call.method}", name: 'Moca');
        break;
    }
    return null;
  }

  // Example API methods (all now return a MocaResult to let the caller inspect success or error)

  static Future<MocaResult<bool?>> initialized() async {
    return await _invokeMethod<bool>('initialized');
  }

  static Future<MocaResult<String?>> getVersion() async {
    return await _invokeMethod<String>('getVersion');
  }

    static Future<MocaResult<String?>> getInstanceId() async {
    return await _invokeMethod<String>('getInstanceId');
  }

  static Future<MocaResult<String?>> getLogLevel() async {
    return await _invokeMethod<String>('getLogLevel');
  }

  static Future<MocaResult<String?>> getPermissionsStatus() async {
    return await _invokeMethod<String>('getPermissionsStatus');
  }

  static Future<MocaResult<bool?>> geoTrackingEnabled() async {
    return await _invokeMethod<bool>('geoTrackingEnabled');
  }

  static Future<MocaResult<bool?>> eventTrackingEnabled() async {
    return await _invokeMethod<bool>('eventTrackingEnabled');
  }

  static Future<MocaResult<String?>> getUserId() async {
    return await _invokeMethod<String>('getUserId');
  }

  static Future<MocaResult<void>> setUserId(String userId) async {
    return await _invokeMethod<void>('setUserId', {'userId': userId});
  }

  static Future<MocaResult<void>> setGeoTrackingEnabled(bool enabled) async {
    return await _invokeMethod<void>('setGeoTrackingEnabled', {'enabled': enabled});
  }

  static Future<MocaResult<void>> setEventTrackingEnabled(bool enabled) async {
    return await _invokeMethod<void>('setEventTrackingEnabled', {'enabled': enabled});
  }

  static Future<MocaResult<String?>> setLogLevel(String logLevel) async {
    return await _invokeMethod<String>('setLogLevel', {'logLevel': logLevel});
  }

  static Future<MocaResult<bool?>> flushEvents() async {
    return await _invokeMethod<bool>('flushEvents');
  }

  static Future<MocaResult<int?>> getQueuedEvents() async {
    return await _invokeMethod<int>('getQueuedEvents');
  }

  static Future<MocaResult<dynamic>> track(String verb,
      {String? item, String? category, dynamic value}) async {
    return await _invokeMethod('track', {
      'verb': verb,
      'item': item,
      'category': category,
      'value': value,
    });
  }

  static Future<MocaResult<dynamic>> trackViewed(String item,
      {String? category, bool? recommended}) async {
    return await _invokeMethod('trackViewed', {
      'item': item,
      'category': category,
      'recommended': recommended ?? false,
    });
  }

  static Future<MocaResult<dynamic>> addToFavList(String item) async {
    return await _invokeMethod('addToFavList', {'item': item});
  }

  static Future<MocaResult<void>> removeFromFavList(String item) async {
    return await _invokeMethod<void>('removeFromFavList', {'item': item});
  }

  static Future<MocaResult<void>> clearFavList() async {
    return await _invokeMethod<void>('clearFavList');
  }

  static Future<MocaResult<void>> addToWishList(String item) async {
    return await _invokeMethod<void>('addToWishList', {'item': item});
  }

  static Future<MocaResult<void>> removeFromWishList(String item) async {
    return await _invokeMethod<void>('removeFromWishList', {'item': item});
  }

  static Future<MocaResult<void>> clearWishList() async {
    return await _invokeMethod<void>('clearWishList');
  }

  static Future<MocaResult<void>> addToCart(String item,
      {String? category,
      required double unitPrice,
      required String currency,
      required double quantity}) async {
    return await _invokeMethod<void>('addToCart', {
      'item': item,
      'category': category,
      'unitPrice': unitPrice,
      'currency': currency,
      'quantity': quantity,
    });
  }

  static Future<MocaResult<void>> updateCart(String item, double quantity) async {
    return await _invokeMethod<void>('updateCart', {'item': item, 'quantity': quantity});
  }

  static Future<MocaResult<void>> removeFromCart(String item) async {
    return await _invokeMethod<void>('removeFromCart', {'item': item});
  }

  static Future<MocaResult<void>> clearCart() async {
    return await _invokeMethod<void>('clearCart');
  }

  static Future<MocaResult<void>> beginCheckout() async {
    return await _invokeMethod<void>('beginCheckout');
  }

  static Future<MocaResult<void>> completeCheckout() async {
    return await _invokeMethod<void>('completeCheckout');
  }

  static Future<MocaResult<dynamic>> trackPurchased(String item,
      {String? category,
      required double unitPrice,
      required String currency,
      required int quantity}) async {
    return await _invokeMethod<dynamic>('trackPurchased', {
      'item': item,
      'category': category,
      'unitPrice': unitPrice,
      'currency': currency,
      'quantity': quantity,
    });
  }

  static Future<MocaResult<dynamic>> trackShared(String item) async {
    return await _invokeMethod<dynamic>('trackShared', {'item': item});
  }

  static Future<MocaResult<bool?>> addTag(String tag, {String? value}) async {
    return await _invokeMethod<bool>('addTag', {'tag': tag, 'value': value});
  }

  static Future<MocaResult<Map?>> getTags() async {
    return await _invokeMethod<Map>('getTags');
  }

  static Future<MocaResult<bool?>> containsTag(String tag) async {
    return await _invokeMethod<bool>('containsTag', {'tag': tag});
  }

  static Future<MocaResult<double?>> getTagValue(String tag) async {
    return await _invokeMethod<double>('getTagValue', {'tag': tag});
  }

  static Future<MocaResult<Map?>> getLastKnownLocation() async {
    return await _invokeMethod<Map>('getLastKnownLocation');
  }

  static Future<MocaResult<bool?>> setRemotePushToken(String token, String provider) async {
    return await _invokeMethod<bool>('setRemotePushToken', {'token': token, 'provider': provider});
  }

  static Future<MocaResult<bool?>> setProperty(String key, Object value) async {
    return await _invokeMethod<bool>('setProperty', {'key': key, 'value': value});
  }

  static Future<MocaResult<Object?>> getProperty(String key) async {
    return await _invokeMethod<Object>('getProperty', {'key': key});
  }

  static Future<MocaResult<bool?>> setProperties(Map<String, dynamic> props) async {
    return await _invokeMethod<bool>('setProperties', props);
  }

  // --- Callback Registrations ---

  /// Register a foreground geofence callback.
  static void onGeofence(MocaRegionCallback? callback) {
    foregroundGeofenceCallback = callback;
  }

  /// Register a foreground beacon callback.
  static void onBeacon(MocaRegionCallback? callback) {
    foregroundBeaconCallback = callback;
  }

  /// Register a foreground region group callback.
  static void onRegionGroup(MocaRegionCallback? callback) {
    foregroundRegionGroupCallback = callback;
  }

  /// Register a foreground action callback.
  static void onAction(MocaActionCallback? callback) {
    foregroundActionCallback = callback;
  }

  /// Register a foreground navigation callback.
  static void onNavigator(MocaNavigatorCallback? callback) {
    foregroundNavigatorCallback = callback;
  }

  /// Register a foreground error callback.
  static void onError(MocaErrorCallback? callback) {
    foregroundErrorCallback = callback;
  }
}