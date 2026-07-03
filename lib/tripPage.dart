import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'GeoFenceScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // <-- Add this import at the top
import 'config_loader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class TripListPage extends StatefulWidget {
  final String driverId; // no need for companyId here, it’s in API
  const TripListPage({super.key, required this.driverId});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  bool isLoading = true;
  List<dynamic> tripData = [];

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Build detailed address with landmark-like details
        final String name = place.name ?? ''; // often a building or landmark
        final String street = place.street ?? '';
        final String subLocality = place.subLocality ?? '';
        final String locality = place.locality ?? ''; // city or area
        final String administrativeArea =
            place.administrativeArea ?? ''; // state

        // Combine only non-empty parts
        final List<String> addressParts =
            [
              name,
              street,
              subLocality,
              locality,
              administrativeArea,
            ].where((part) => part.isNotEmpty).toList();

        return addressParts.join(', ');
      } else {
        return "Unknown location";
      }
    } catch (e) {
      print("Error getting address: $e");
      return "Unable to fetch location";
    }
  }

  Future<void> _fetchTrips() async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/getVehicleAvailability/$today/${widget.driverId}',
      ),
    );

    try {
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData["status"]["code"] == 200) {
          setState(() {
            tripData = jsonData["data"];
            isLoading = false;
          });
        } else {
          _showError("No data found.");
        }
      } else {
        _showError("Server error ${response.statusCode}");
      }
    } catch (e) {
      _showError("Network error: $e");
    }
  }

  void _showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF4F5F9),
      // appBar: AppBar(
      //   title: const Text("Trip List"),
      //   backgroundColor: const Color(0xFF010440),
      //   centerTitle: true,
      // ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : tripData.isEmpty
              ? const Center(child: Text("No upcoming trips"))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tripData.length,
                itemBuilder: (context, i) {
                  final company = tripData[i];
                  final vehicle = company["vehicles"][0];
                  final subCustomers = vehicle["subCustomers"];
                  final firstStop = subCustomers.first;
                  final lastStop = subCustomers.last;
                  final subCustomerIds =
                      subCustomers
                          .map<int>((sc) => sc["subCustomerId"] as int)
                          .toList();

                  final companyIds =
                      subCustomers
                          .map<int>((sc) => sc["companyId"] as int)
                          .toList();

                  String tripLabel;
                  if (vehicle["status"] == 1) {
                    tripLabel = "Completed Trip";
                  } else if (i == 0) {
                    tripLabel = "Upcoming Trip";
                  } else {
                    tripLabel = "Following Trip";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEFE5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Header
                        Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: Color(0xFF010440),
                            ),
                            SizedBox(width: 8),
                            Text(
                              tripLabel,
                              style: TextStyle(
                                color: Color(0xFF010440),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "${'trip_number'.tr()}: ${(vehicle["id"] is List) ? vehicle["id"].join('') : vehicle["id"]}",
                          style: const TextStyle(
                            color: Color(0xFF010440),
                            fontSize: 13,
                          ),
                        ),

                        const Divider(color: Color(0xFFF15F28), thickness: 1),
                        const SizedBox(height: 10),

                        // 🔹 Duration
                        Text(
                          "duration".tr(),
                          style: TextStyle(
                            color: Color(0xFF010440),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${firstStop["deliveryTime"]} hrs - ${company["counterTime"]} hrs",
                          style: const TextStyle(
                            color: Color(0xFF010440),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔹 From / Destination
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 FROM Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "from".tr(),
                                    style: TextStyle(color: Color(0xFF010440)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Paranur",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF010440),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 10),

                            // 🔹 DESTINATION Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "destination".tr(),
                                    style: TextStyle(color: Color(0xFF010440)),
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<String>(
                                    future: _getAddressFromCoordinates(
                                      lastStop["latitude"]?.toDouble() ?? 0.0,
                                      lastStop["longitude"]?.toDouble() ?? 0.0,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                          "Fetching location...",
                                          style: TextStyle(color: Colors.grey),
                                        );
                                      } else if (snapshot.hasError) {
                                        return const Text(
                                          "Unable to fetch location",
                                          style: TextStyle(color: Colors.red),
                                        );
                                      } else {
                                        return Text(
                                          snapshot.data ?? "Unknown location",
                                          textAlign: TextAlign.right,
                                          softWrap: true,
                                          maxLines: null,
                                          style: const TextStyle(
                                            color: Color(0xFF010440),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 🔹 Stops
                        Text(
                          "stops".tr(),
                          style: TextStyle(
                            color: Color(0xFF010440),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${subCustomers.length} stops",
                          style: const TextStyle(
                            color: Color(0xFF010440),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 16),
                        // 🔹 Show button only for the first (upcoming) trip
                        if (i == 0 && vehicle["status"] != 1)
                          // 🔹 Start Trip Button
                          ElevatedButton(
                            onPressed: () {
                              final totalCrates = subCustomers.fold<int>(0, (
                                int prev,
                                dynamic stop,
                              ) {
                                if (stop == null ||
                                    stop is! Map<String, dynamic>)
                                  return prev;

                                final count = stop["crateCount"];
                                if (count is int) return prev + count;
                                if (count is String)
                                  return prev + (int.tryParse(count) ?? 0);
                                return prev;
                              });

                              final totalPax = subCustomers.fold<int>(0, (
                                int prev,
                                dynamic stop,
                              ) {
                                if (stop == null ||
                                    stop is! Map<String, dynamic>)
                                  return prev;

                                final count = stop["paxCount"];
                                if (count is int) return prev + count;
                                if (count is String)
                                  return prev + (int.tryParse(count) ?? 0);
                                return prev;
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => TripOrderPage(
                                        companyIds: companyIds,
                                        firstStopTime:
                                            firstStop["deliveryTime"],
                                        // static
                                        lastStopTime:
                                            lastStop["deliveryTime"].toString(),
                                        cratesCount: totalCrates.toString(),
                                        // ✅ total crates
                                        boxesCount: totalPax.toString(),
                                        toLat: lastStop["latitude"],
                                        toLng: lastStop["longitude"],
                                        id: List<int>.from(vehicle["id"]),
                                        subCustomerIds: subCustomerIds,
                                        driverId: widget.driverId,
                                        vehicleId:
                                            vehicle["vehicleId"].toString(),
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF15F28),
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "start_the_trip".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class TripOrderPage extends StatefulWidget {
  final List<int> companyIds;
  final String firstStopTime;
  final String lastStopTime;
  final String cratesCount;
  final String boxesCount;
  final double toLat;
  final double toLng;
  final List<int> id;
  final List<int> subCustomerIds;
  final String driverId;
  final String vehicleId;

  const TripOrderPage({
    super.key,
    required this.companyIds,
    required this.firstStopTime,
    required this.lastStopTime,
    required this.cratesCount,
    required this.boxesCount,
    required this.toLat,
    required this.toLng,
    required this.id,
    required this.subCustomerIds,
    required this.driverId,
    required this.vehicleId,
  });

  @override
  State<TripOrderPage> createState() => _TripOrderPageState();
}

class _TripOrderPageState extends State<TripOrderPage> {
  late GoogleMapController mapController;
  final LatLng _fromLocation = const LatLng(12.729974, 79.984963);
  late LatLng _toLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _trackingTimer; // 👈 periodic timer
  String? _nextStopLocation;
  String? routeDistance;
  String? routeDuration;

  @override
  void initState() {
    super.initState();
    _toLocation = LatLng(widget.toLat, widget.toLng);
    _setMarkers();
    _loadGoogleRoute(); // 👈 USE GOOGLE ROUTE
    _getNextStopAddress();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel(); // stop when leaving page
    super.dispose();
  }

  Future<void> _loadGoogleRoute() async {
    final String apiKey = "AIzaSyAI_PGqAd3ZcmEfWk3jQNEIeBMdZxQDyew";

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${_fromLocation.latitude},${_fromLocation.longitude}"
        "&destination=${_toLocation.latitude},${_toLocation.longitude}"
        "&mode=driving"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final points = data["routes"][0]["overview_polyline"]["points"];

        List<LatLng> polylineCoords = _decodePolyline(points);

        final distance = data["routes"][0]["legs"][0]["distance"]["text"];
        final duration = data["routes"][0]["legs"][0]["duration"]["text"];

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              width: 6,
              color: Colors.blue,
              points: polylineCoords,
            ),
          );

          routeDistance = distance;
          routeDuration = duration;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // 🔹 Get Current GPS
  Future<Position> _getCurrentLocation() async {
    // Directly fetch the current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 🔹 Call Tracking API
  Future<void> _sendTrackingData() async {
    try {
      final pos = await _getCurrentLocation();
      final payload = {
        "tripId": widget.id, // ✅ Replace with your actual trip IDs dynamically
        "latitude": pos.latitude,
        "longitude": pos.longitude,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.localBaseUrl}/api/vehicleDispatchTracking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload), // ✅ Must encode to JSON
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Tracking data sent successfully: ${response.body}");
      } else {
        debugPrint("⚠️ Tracking failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error sending tracking data: $e");
    }
  }

  // 🔹 Start Tracking Immediately and Repeat Every 2 Mins
  void _startTripTracking() {
    _sendTrackingData(); // send once immediately
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _sendTrackingData();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Trip started! Tracking every 2 minutes."),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<BitmapDescriptor> _getResizedMarker(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? resizedData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
  }

  void _setMarkers() async {
    final BitmapDescriptor driverIcon = await _getResizedMarker(
      'assets/images/driver.png',
      100,
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('from'),
        position: _fromLocation,
        infoWindow: const InfoWindow(title: 'Start: FoodSwing'),
        icon: driverIcon,
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('to'),
        position: _toLocation,
        infoWindow: InfoWindow(
          title: 'Next Stop: ${_nextStopLocation ?? "Loading..."}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String _calculateEta(String firstStopTime) {
    try {
      final t = DateFormat("HH:mm").parse(firstStopTime);
      final eta = t.add(const Duration(minutes: 5));
      return DateFormat("HH:mm").format(eta);
    } catch (_) {
      return firstStopTime;
    }
  }

  Future<void> _getNextStopAddress() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.toLat,
        widget.toLng,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // 🏷️ Create a detailed address with landmarks
        final detailedAddress = [
          place.name, // Place or building name
          place.street, // Street name
          place.subLocality, // Area or landmark
          place.locality, // City or town
          place.administrativeArea, // State
        ].where((element) => element != null && element!.isNotEmpty).join(", ");

        setState(() {
          _nextStopLocation = detailedAddress;
        });
      } else {
        setState(() {
          _nextStopLocation = "Unknown location";
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      setState(() {
        _nextStopLocation = "Unable to fetch location";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "track_order".tr(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _fromLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 🔹 Trip Info
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF000080),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.firstStopTime} hrs.",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "next_stop".tr() +
                              ": ${(_nextStopLocation ?? "fetching".tr())}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   "ETA: ${_calculateEta(widget.firstStopTime)} hrs",
                        //   style: const TextStyle(
                        //     color: Colors.white70,
                        //     fontSize: 13,
                        //   ),
                        // ),
                        if (routeDistance != null)
                          Text(
                            "${'distance'.tr()}: $routeDistance | ${'time_d'.tr()}: $routeDuration",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 🔹 Start Trip Button
                  ElevatedButton(
                    onPressed: _startTripTracking, // 👈 call the function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "start_trip".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    // onPressed: () {},
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => GeoFenceScreen(
                                companyIds: widget.companyIds,
                                driverId: widget.driverId,
                                subCustomerIds: widget.subCustomerIds,
                                vehicleId: widget.vehicleId,
                              ),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "geo".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔹 Bottom Delivery Info Card
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF000080),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// 🚚 Deliver Icon + Label
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "deliver".tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  /// 📦 Crates Section
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: const Color(0xFFF15F28),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "crates".tr(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.cratesCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  /// 📦 Boxes Section
                  Row(
                    children: [
                      Icon(
                        Icons.all_inbox_outlined,
                        color: const Color(0xFFF15F28),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "boxes".tr(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.boxesCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class LocationDisclosurePage extends StatelessWidget {
//   final VoidCallback onPermissionGranted;
//
//   const LocationDisclosurePage({super.key, required this.onPermissionGranted});
//
//   Future<void> _requestLocationPermissions(BuildContext context) async {
//     // STEP 1: Check Location Services (GPS) first
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Request user to enable GPS
//       await Geolocator.openLocationSettings();
//
//       // Check again after returning
//       serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Please enable Location Services (GPS)."),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }
//
//     // STEP 2: Request foreground location permission
//     PermissionStatus status = await Permission.location.request();
//
//     // STEP 3: Request background location (for trip tracking)
//     if (await Permission.location.isGranted) {
//       await Permission.locationAlways.request();
//     }
//
//     // FINAL CHECK
//     if (await Permission.locationAlways.isGranted ||
//         await Permission.locationWhenInUse.isGranted) {
//       onPermissionGranted();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Location permission is required to continue."),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Why Sauceit Needs Your Location",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF010440),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "• Your live trip route requires precise location.\n"
//                   "• We track your path only during active trips.\n"
//                   "• Location is never used when you are off duty.\n"
//                   "• Background location is used so the trip\n"
//                   "  continues even if the screen is off.",
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 40),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () => _requestLocationPermissions(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFFF15F28),
//                   minimumSize: const Size(double.infinity, 55),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   "Allow Location Access",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
