import 'package:flutter/material.dart';
import 'dart:async';
import 'package:moca_flutter/moca_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Needed only for Clipboard

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

      // Otherwise let SDK handle deep links by default.
      return false;
    });
  }

/// Requests push notification and location permissions by first showing an 
  /// informational dialog (with a “Continue” button) before invoking the OS prompt.
  Future<void> _requestPermissions() async {
    // Show information about push notifications.
    await _showInfoDialog(
      title: "Push Notifications",
      message:
          "We use push notifications to keep you updated about local events, exclusive offers, and personalized experiences based on your location. Tap 'Continue' to enable push notifications.",
    );

    // Now, ask the OS for push notification permission.
    PermissionStatus notificationStatus = await Permission.notification.request();
    print("Notification permission status: $notificationStatus");

    // Show information about location services.
    await _showInfoDialog(
      title: "Location Access",
      message:
          "This app uses your location to deliver personalized, location-based experiences such as local deals and event recommendations. Tap 'Continue' to enable location services.",
    );

    // Now, ask the OS for location permission.
    PermissionStatus locationStatus = await Permission.location.request();
    print("Location permission status: $locationStatus");
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
