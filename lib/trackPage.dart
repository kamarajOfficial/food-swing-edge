import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:convert';
import 'config_loader.dart';
import 'package:geocoding/geocoding.dart';

class TrackOrderPage extends StatefulWidget {
  final String companyId;

  const TrackOrderPage({super.key, required this.companyId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  double? _fromDriverLat;
  double? _fromDriverLng;
  double? _toDriverLat;
  double? _toDriverLng;
  String? _driverName;
  String? _driverPhone;
  String? _deliveryLocation;

  @override
  void initState() {
    super.initState();
    _fetchTrackOrder();
  }

  Future<void> _getRoutePolyline() async {
    if (_fromDriverLat == null || _fromDriverLng == null) return;

    final String apiKey = "AIzaSyAI_PGqAd3ZcmEfWk3jQNEIeBMdZxQDyew";

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$_fromDriverLat,$_fromDriverLng"
        "&destination=$_toDriverLat,$_toDriverLng"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final points = data["routes"][0]["overview_polyline"]["points"];

        List<LatLng> polylineCoords = _decodePolyline(points);

        final polyline = Polyline(
          polylineId: const PolylineId("route"),
          points: polylineCoords,
          width: 6,
          color: Colors.blue,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(polyline);
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

  Future<void> _fetchTrackOrder() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/vehicleTrackOrder/${widget.companyId}',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];

        if (data == null) {
          setState(() => _isLoading = false);
          return;
        }

        setState(() {
          _fromDriverLat = data['fromLatitude']?.toDouble();
          _fromDriverLng = data['fromLongitude']?.toDouble();
          _toDriverLat = data['toLatitude']?.toDouble();
          _toDriverLng = data['toLongitude']?.toDouble();
          _driverName = data['driverName'];
          _driverPhone = data['mobileNumber'].toString();
          _isLoading = false;
        });

        if (_toDriverLat != null && _toDriverLng != null) {
          _getAddressFromCoordinates(_toDriverLat!, _toDriverLng!);
        }
        _addMapMarkers();
        await _getRoutePolyline(); // 👈 use Google Directions API

        // _addPolyline(); // ✅ add polyline only after fetching driver data
      } else if (response.statusCode == 404) {
        setState(() => _isLoading = false);
        print('ℹ️ No data found (404).');
        return;
      } else {
        throw Exception(
          'Failed to fetch data (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!e.toString().contains('404')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _deliveryLocation =
              "${place.name}, ${place.locality}, ${place.administrativeArea}";
        });
      } else {
        setState(() => _deliveryLocation = "Unknown location");
      }
    } catch (e) {
      print("Error fetching address: $e");
      setState(() => _deliveryLocation = "Unable to fetch location");
    }
  }

  Future<void> _addMapMarkers() async {
    if (_fromDriverLat == null || _fromDriverLng == null) return;

    final BitmapDescriptor driverIcon = await _getResizedMarker(
      'assets/images/driver.png',
      100,
    );

    final LatLng driverPosition = LatLng(_toDriverLat!, _toDriverLng!);

    final LatLng currentPosition = LatLng(_fromDriverLat!, _fromDriverLng!);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: currentPosition, // ✅ use actual driver position
          icon: driverIcon,
          infoWindow: InfoWindow(title: _driverName ?? 'Driver Location'),
        ),
        Marker(
          markerId: const MarkerId('delivery'),
          position: driverPosition,
          infoWindow: const InfoWindow(title: 'Delivery Address'),
        ),
      };
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(driverPosition, 14.0),
    );
  }

  Future<BitmapDescriptor> _getResizedMarker(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width, // 👈 set small width (e.g., 60 for small icon)
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? resizedData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(resizedData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialPosition =
        (_fromDriverLat != null && _fromDriverLng != null)
            ? LatLng(_fromDriverLat!, _fromDriverLng!)
            : const LatLng(12.729974, 79.984963);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        elevation: 0,
        title: Text(
          "tracking".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // 👈 makes back icon white if used
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 13.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryCard(),
                      const SizedBox(height: 20),
                      _buildOrderTimeline(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Icon(Icons.delivery_dining, color: Color(0xFFF15F28)),
                SizedBox(width: 8),
                Text(
                  "delivery_your_order".tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Text(
            "coming".tr(),
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: const Color(0xFFF15F28)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${"you".tr()} - ${_deliveryLocation ?? "fetching".tr()}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/images/driver.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverName ?? "loading".tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${'delivery'.tr()} • ${_driverPhone ?? '--'}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_driverPhone != null) _launchPhone(_driverPhone!);
                },
                icon: const Icon(Icons.phone, color: Colors.green),
              ),
              IconButton(
                onPressed: () {
                  if (_driverPhone != null) _launchSMS(_driverPhone!);
                },
                icon: const Icon(Icons.message, color: const Color(0xFFF15F28)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer')),
      );
    }
  }

  Future<void> _launchSMS(String phoneNumber) async {
    final Uri smsUri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open SMS app')));
    }
  }

  Widget _buildOrderTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusTile(
          "cooking".tr(),
          "2:15 PM",
          isActive: true,
          imagePath: "assets/images/media.gif",
        ),
        _buildStatusTile(
          "food_ready".tr(),
          "pending".tr(),
          imagePath: "assets/images/media-1.gif",
        ),
        _buildStatusTile(
          "dispatched".tr(),
          "pending".tr(),
          imagePath: "assets/images/media-4.gif",
        ),
        _buildStatusTile(
          "in_transit".tr(),
          "pending".tr(),
          imagePath: "assets/images/media-6.gif",
        ),
        _buildStatusTile(
          "food_delivered".tr(),
          "pending".tr(),
          imagePath: "assets/images/media-7.gif",
        ),
        _buildStatusTile(
          "completed".tr(),
          "pending".tr(),
          imagePath: "assets/images/media-8.gif",
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStatusTile(
    String title,
    String time, {
    required String imagePath,
    bool isActive = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Container(
              width: 100,
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: isActive ? 50 : 26,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            if (!isLast)
              Container(height: 28, width: 2, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    fontSize: isActive ? 20 : 16,
                    color: isActive ? Colors.black : Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
