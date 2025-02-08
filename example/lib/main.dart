import 'package:flutter/material.dart';
import 'dart:async';
import 'package:moca_flutter/moca_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Needed only for Clipboard
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: true,
    navigatorObservers: [
      // add this code to automatically track screen transitions in Flutter app
      Moca.getNavigatorObserver()
    ],
    routes: {
      '/': (context) => MyApp(),
      '/productSearch': (context) => ProductSearchScreen(),
    },
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _mocaVersion;
  final Map<String, String?> _buttonResults = {};
  String? _receivedEvent;

  @override
  void initState() {
    super.initState();
    // Schedule the permission requests after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
    initMoca();
    fetchMocaVersion();
  }

  Future<void> fetchMocaVersion() async {
    var res = await Moca.getVersion();
    String? version = res.isSuccess ? res.data : "error";
    setState(() {
      _mocaVersion = version;
    });
  }

  Future<void> initMoca() async {
    Moca.initializeSDK('LlaH-4dSQHKFgjC7VWGMXw', 'UDR2mcGJy13abW24u/1aposhmUk=');
    Moca.setUserId('flutter');
    Moca.setProperties({'foo': 'bar', 'bax': true, 'qux': 1});
    Moca.setLogLevel('info');

    Moca.onAction((action, args) {
      if (action == "custom") {
        String customAttribute = args?['customAttribute'];
        setState(() {
          _receivedEvent = "Custom action $customAttribute";
        });
        Future.delayed(Duration(seconds: 5), () {
          setState(() {
            _receivedEvent = "";
          });
        });
      }      
    });
    // Listen for geofence events
    Moca.onGeofence((verb, geofence) {
      String name = geofence?['name'] ?? 'Unnamed';
      setState(() {
        _receivedEvent = "$verb $name geofence";
      });
      Future.delayed(Duration(seconds: 5), () {
        setState(() {
          _receivedEvent = "";
        });
      });
    });

    Moca.onNavigator((uri) {
      // Implement handling of known deep links here
      // and then return true if handled.      
      setState(() {
        _receivedEvent = "Open deeplink $uri";
      });
      Future.delayed(Duration(seconds: 5), () {
        setState(() {
          _receivedEvent = "";
        });
      });
      // Parse the string into a Uri.
      final url = Uri.tryParse(uri);
      if (url != null) {
          // Check internal deeplinks
          if (uri.endsWith('/productSearch')) {
            // Navigate to the product search page.
            Navigator.pushNamed(context, '/productSearch');
          } else {
             // Open the URL in the default external browser.
             launchUrl(url, mode: LaunchMode.externalApplication);
          }
      }
    });
  }

  /// Helper functions to get and set persistent flags using SharedPreferences.
  Future<bool> _getFlag(String key) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
  }

  Future<void> _setFlag(String key, bool value) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
  }

  /// Requests push notification and location permissions.
  /// Each info dialog is shown only if:
  ///   - The permission is not yet granted.
  ///   - The info dialog has not been shown before (persisted via SharedPreferences).
  Future<void> _requestPermissions() async {

    // await _requestPushPermission();
    // await _requestLocationPermission();
    // await _requestLocalDevicesPermission();
  }

  Future<void> _requestPushPermission() async {
    // Check current push notification permission status.
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (notificationStatus.isGranted) {
      print("Push notifications permission already granted.");
      return;
    }

    // Use a separate flag for push notifications.
    bool pushDialogShown = await _getFlag('pushPermissionDialogShown');
    if (!pushDialogShown) {
      // Show your custom info dialog first.
      await _showInfoDialog(
        title: "Push Notifications",
        message:
            "We use push notifications to keep you updated about local events, exclusive offers, and personalized experiences based on your location. Tap 'Continue' to enable push notifications.",
      );
      // Now request the OS push notification permission.
      PermissionStatus newNotificationStatus = await Permission.notification.request();
      print("Notification permission status: $newNotificationStatus");
      // Save the flag AFTER the OS dialog is requested.
      await _setFlag('pushPermissionDialogShown', true);
    }
  }

  Future<void> _requestLocationPermission() async {
    // Check current location permission status.
    PermissionStatus locationStatus = await Permission.location.status;
    if (locationStatus.isGranted) {
      print("Location permission already granted.");
      return;
    }

    // Use a separate flag for location permissions.
    bool locationDialogShown = await _getFlag('locationPermissionDialogShown');
    if (!locationDialogShown) {
      // Show your custom info dialog.
      await _showInfoDialog(
        title: "Location Access",
        message:
            "This app uses your location to deliver personalized, location-based experiences such as local deals and event recommendations. Tap 'Continue' to enable location services.",
      );
      // Request the OS location permission.
      PermissionStatus newLocationStatus = await Permission.location.request();
      print("Location permission status: $newLocationStatus");
      // Save the flag only after the OS dialog is requested.
      await _setFlag('locationPermissionDialogShown', true);
    }
  }

  Future<void> _requestLocalDevicesPermission() async {
    // Check the current status of the Bluetooth permission.
    PermissionStatus status = await Permission.bluetooth.status;
    if (!status.isGranted) {
      // Replace this with the actual local device permission flow if needed.
      // Here we assume a similar custom-dialog flow, even if there isn’t an OS dialog.
      bool localDevicesDialogShown = await _getFlag('localDevicesPermissionDialogShown');
      if (!localDevicesDialogShown) {
        await _showInfoDialog(
          title: "Local Devices",
          message:
              "This app uses local device permissions for certain features. Tap 'Continue' to enable.",
        );
        // Request the Bluetooth permission.
        PermissionStatus newStatus = await Permission.bluetooth.request();
        print("Location permission status: $newStatus");
        // If there were an OS dialog to request a permission, you would call it here.
        // For now, simply store the flag.
        await _setFlag('localDevicesPermissionDialogShown', true);
      }
    }
  }

  /// A helper function that shows a simple informational dialog with a "Continue" button.
  Future<void> _showInfoDialog({required String title, required String message}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap the button to continue.
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(
                title == "Push Notifications" ? Icons.notifications_active : Icons.location_on,
                color: Colors.blue,
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Continue"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateResult(String key, String result) {
    setState(() {
      _buttonResults[key] = result;
    });
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _buttonResults.remove(key);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 24, // Adjust height to match title
              ),
              SizedBox(width: 8),
              Text('Moca Flutter Example'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    buildButtonRow(
                      'Get Location Permissions',
                      'location_permission',
                      () async {
                        var resp = await Moca.getPermissionsStatus();
                        _updateResult('location_permission', resp.isSuccess ? resp.data.toString() : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Track Click',
                      'track_click',
                      () async {
                        var resp = await Moca.track("click");
                        _updateResult('track_click', resp.isSuccess ? (resp.data == true ? 'Success' : 'Cannot track') : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Track Product View',
                      'track_view',
                      () async {
                        var resp = await Moca.trackViewed("apple_174", category: "Fruits");
                        _updateResult('track_view', resp.isSuccess ? (resp.data == true ? 'Success' : 'Cannot track') : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Track Purchase',
                      'track_purchase',
                      () async {
                        var resp = await Moca.trackPurchased("apple_174", category: "Fruits", unitPrice: 3.51, currency: 'eur', quantity: 2);
                        _updateResult('track_purchase', resp.isSuccess ? (resp.data == true ? 'Success' : 'Cannot track') : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Add Tag',
                      'add_tag',
                      () async {
                        var resp = await Moca.addTag("loyal", value:"+1");
                        _updateResult('add_tag', resp.isSuccess ? (resp.data == true ? 'Success' : 'Cannot add tag') : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Count Queued Events',
                      'count_queued_events',
                      () async {
                        var resp = await Moca.getQueuedEvents();
                        _updateResult('count_queued_events', resp.isSuccess ? resp.data.toString() : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Flush Events',
                      'flush_events',
                      () async {
                        var resp = await Moca.flushEvents();
                        _updateResult('flush_events', resp.isSuccess ? (resp.data == true ? 'Success' : 'Cannot flush') : 'Error');
                      },
                    ),
                    buildButtonRow(
                      'Navigate',
                      'navigate',
                      () {
                        Navigator.pushNamed(context, '/productSearch');
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_receivedEvent ?? ""}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            // Wrap the version text in a GestureDetector to handle taps.
            GestureDetector(
              onTap: () async {
                // Get the instance ID from Moca.
                var instanceIdResult = await Moca.getInstanceId();
                String instanceId;
                if (instanceIdResult.isSuccess) {
                  instanceId = instanceIdResult.data ?? '';
                } else {
                  instanceId = "Error retrieving instance ID";
                }
                // Copy the instance ID to the clipboard.
                await Clipboard.setData(ClipboardData(text: instanceId));
                // Optionally, show a SnackBar to confirm the copy action.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Moca Instance ID copied to clipboard!"),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Moca SDK Version: $_mocaVersion',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget buildButtonRow(String label, String key, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          ),
          Text(
            _buttonResults[key] ?? '',
            style: TextStyle(color: _buttonResults[key] == 'Error' ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
  }
}


class ProductSearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product Search Screen")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Back to Main Screen"),
        ),
      ),
    );
  }
}
