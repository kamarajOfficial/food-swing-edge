import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ProminentDisclosurePage extends StatelessWidget {
  final VoidCallback onPermissionGranted;

  const ProminentDisclosurePage({super.key, required this.onPermissionGranted});

  Future<void> _requestPermissions(BuildContext context) async {
    // STEP 1: Ensure GPS is ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enable Location Services (GPS).",
              style: TextStyle(fontFamily: 'OpenSans'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // STEP 2: Foreground location
    PermissionStatus locStatus = await Permission.location.request();

    // STEP 3: Background location (required for DRIVER ACCOUNTS)
    if (locStatus.isGranted) {
      await Permission.locationAlways.request();
    }

    // FINAL CHECK
    if (await Permission.locationAlways.isGranted ||
        await Permission.locationWhenInUse.isGranted) {
      onPermissionGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission is required to continue.",
            style: TextStyle(fontFamily: 'OpenSans'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Why Sauceit Needs Your Permissions",
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF010440),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "• Sauceit requires access to your device’s location to enable delivery tracking and support accurate navigation for drivers.\n"
                  "• Your location is used to improve route accuracy, live tracking, and service reliability.\n"
                  "• Location data may be collected even when the app is closed or not in use to support continuous driver tracking only for driver accounts.\n"
                  "• Background location is never used for customer users.\n"
                  "• Photo and media access is requested only when you upload images inside the app.",
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: () => _requestPermissions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF15F28),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Allow Permissions",
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
