import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'config_loader.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class AttendancePage extends StatefulWidget {
  final String companyId;

  const AttendancePage({super.key, required this.companyId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> attendanceList = [];
  bool loading = true;
  bool saving = false;
  double? companyLatitude;
  double? companyLongitude;
  List<Map<String, dynamic>> companyList = [];
  bool loadingCompanies = false;
  int? selectedCompanyId;
  String? selectedCompanyName;

  int get presentCount =>
      attendanceList.where((u) => u["status"] == "P").length;

  int get absentCount => attendanceList.where((u) => u["status"] == "A").length;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<File> addLocationTextOnImage({
    required File originalImage,
    required Map<String, String> locationText,
  }) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception("Image decode failed");

    final lines = [
      locationText["title"] ?? "",
      locationText["address"] ?? "",
      locationText["latlng"] ?? "",
      "Time: ${locationText["time"] ?? ""}",
    ];

    final font = img.arial48;
    const lineHeight = 80;

    const topPadding = 1500; // ✅ adjust if needed
    const bottomPadding = 1500;

    final rectHeight = (lines.length * lineHeight) + topPadding + bottomPadding;

    // 🎨 Colors
    final black = img.ColorUint8.rgba(0, 0, 0, 180);
    final white = img.ColorUint8.rgba(255, 255, 255, 255);

    // 🟫 Background rectangle
    img.fillRect(
      image,
      x1: 0,
      y1: image.height - rectHeight,
      x2: image.width,
      y2: image.height,
      color: black,
    );

    // ✍️ Draw each line
    int y = image.height - rectHeight + topPadding;

    for (final line in lines) {
      img.drawString(image, line, font: font, x: 12, y: y, color: white);
      y += lineHeight;
    }

    final dir = await getTemporaryDirectory();
    final newPath =
        "${dir.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final newFile = File(newPath)
      ..writeAsBytesSync(img.encodeJpg(image, quality: 90));

    return newFile;
  }

  Future<void> _fetchAttendance() async {
    try {
      final url = Uri.parse(
        "${AppConfig.localBaseUrl}/api/getAllAttendance/${widget.companyId}",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        /// ✅ Handle no data case
        if (json["data"] == null ||
            json["data"]["users"] == null ||
            (json["data"]["users"] as List).isEmpty) {
          setState(() {
            attendanceList = [];
            loading = false;
          });

          _showMsg("No attendance data found");
          return;
        }

        final users = json["data"]["users"] as List;
        final data = json["data"];

        companyLatitude = (data["latitude"] as num?)?.toDouble();
        companyLongitude = (data["longitude"] as num?)?.toDouble();

        print("🏢 Company Location: $companyLatitude , $companyLongitude");

        setState(() {
          attendanceList =
              users.map((u) {
                return {
                  "id": u["id"],
                  "userId": u["userId"],
                  "name": u["username"],
                  "employeeId": u["employeeId"],
                  "designation": u["designation"],
                  "switchedCompanyId": u["switchedCompanyId"],
                  "switchedCompanyName": u["switchedCompanyName"], // ✅ from API
                  "status": u["status"],
                  "photo": u["proof"],
                  "imageBytes": null,
                  "location": null,
                  "isSubmitting": false, // ✅ ADD THIS
                };
              }).toList();

          loading = false;
        });
      } else {
        _showMsg("Server error: ${res.statusCode}");
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      _showMsg("Error: $e");
    }
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters

    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<void> _downloadProofImage(int index) async {
    try {
      final int attachmentId = attendanceList[index]["id"];

      final url = Uri.parse(
        "${AppConfig.localBaseUrl}/api/attendanceAttachmentDownload/$attachmentId",
      );

      print("⬇️ Downloading proof: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          attendanceList[index]["imageBytes"] = response.bodyBytes;
        });

        print("✅ Proof downloaded (${response.bodyBytes.length} bytes)");
      } else {
        print("❌ Download failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error downloading proof: $e");
    }
  }

  Future<void> _showDistancePopup(double distanceMeters) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF15F28)),
              SizedBox(width: 8),
              Expanded(
                // ✅ prevents overflow
                child: Text("Warning", overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: Text(
            "You are ${distanceMeters.toStringAsFixed(0)} meters away from the site location.\n\n"
            "It is okay to submit attendance.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchCompanies() async {
    try {
      setState(() => loadingCompanies = true);

      final url = Uri.parse(
        "${AppConfig.localBaseUrl}/api/companyAllGetListMobile/list",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final List data = json["data"] ?? [];

        setState(() {
          companyList =
              data.map((c) => {"id": c["id"], "name": c["name"]}).toList();
        });
      } else {
        _showMsg("Failed to load companies");
      }
    } catch (e) {
      _showMsg("Company load error: $e");
    } finally {
      setState(() => loadingCompanies = false);
    }
  }

  Future<void> _showCompanyPicker(int userId) async {
    if (companyList.isEmpty) {
      await _fetchCompanies();
    }

    List<Map<String, dynamic>> filteredList = List.from(companyList);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("select_company").tr(),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child:
                    loadingCompanies
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          children: [
                            /// 🔍 Search Box
                            TextField(
                              decoration: InputDecoration(
                                hintText: "search_company".tr(),
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  filteredList =
                                      companyList
                                          .where(
                                            (company) => company["name"]
                                                .toString()
                                                .toLowerCase()
                                                .contains(value.toLowerCase()),
                                          )
                                          .toList();
                                });
                              },
                            ),

                            const SizedBox(height: 10),

                            /// 📋 Company List
                            Expanded(
                              child:
                                  filteredList.isEmpty
                                      ? const Center(
                                        child: Text("No company found"),
                                      )
                                      : ListView.builder(
                                        itemCount: filteredList.length,
                                        itemBuilder: (context, index) {
                                          final company = filteredList[index];

                                          return ListTile(
                                            title: Text(company["name"]),
                                            trailing:
                                                selectedCompanyId ==
                                                        company["id"]
                                                    ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    )
                                                    : null,
                                            onTap: () async {
                                              final companyId = company["id"];
                                              final companyName =
                                                  company["name"];

                                              setState(() {
                                                final idx = attendanceList
                                                    .indexWhere(
                                                      (u) =>
                                                          u["userId"] == userId,
                                                    );

                                                if (idx != -1) {
                                                  attendanceList[idx]["switchedCompanyId"] =
                                                      companyId;
                                                  attendanceList[idx]["switchedCompanyName"] =
                                                      companyName;
                                                }
                                              });

                                              Navigator.pop(context);

                                              /// ✅ Update employee company
                                              await _updateEmployeeCompany(
                                                userId: userId,
                                                companyId: companyId,
                                              );

                                              /// ✅ OPTIONAL: Save attendance only after selection
                                              await _saveAttendanceFormData(
                                                userId: userId,
                                                status: "",
                                                // or keep existing status if needed
                                                imagePath: null,
                                                latitude: null,
                                                longitude: null,
                                                switchedCompanyId: companyId,
                                              );

                                              /// 🔄 Refresh list
                                              await _fetchAttendance();
                                            },
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateEmployeeCompany({
    required int userId,
    required int companyId,
  }) async {
    try {
      final url = Uri.parse("${AppConfig.localBaseUrl}/api/updateEmployee/$userId");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"companyId": companyId}),
      );

      if (response.statusCode == 200) {
        _showMsg("✅ Company updated successfully");
      } else {
        print(response.body);
        _showMsg("❌ Failed to update company");
      }
    } catch (e) {
      _showMsg("Update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("attendance").tr(),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Light watermark background image (zoomed out a bit)
          Center(
            child: Opacity(
              opacity: 0.05, // Light shade for watermark
              child: Transform.scale(
                scale: 1.0,
                // 👈 Zoom out image (0.7 = 70% of its original size)
                child: Image.asset(
                  'assets/images/watermark.jpg',
                  fit: BoxFit.contain, // keeps full image visible
                ),
              ),
            ),
          ),

          /// MAIN CONTENT
          loading
              ? const Center(child: CircularProgressIndicator())
              : attendanceList.isEmpty
              ? const Center(
                child: Text(
                  "No attendance data available",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: attendanceList.length,
                itemBuilder: (context, index) {
                  final user = attendanceList[index];
                  final status = user["status"];
                  final bool isLocked =
                      saving ||
                      user["isSubmitting"] == true ||
                      status == "P" ||
                      status == "A" ||
                      status == ""; // ✅ empty status also locked

                  /// 🔥 Auto download proof once
                  if (status == "P" &&
                      user["photo"] != null &&
                      user["imageBytes"] == null) {
                    _downloadProofImage(index);
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// NAME
                          Text(
                            "${user["name"]} - ${user["employeeId"]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user["designation"] ?? "",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// PRESENT / ABSENT
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  avatar: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  label: const Text("present").tr(),
                                  selected: status == "P",
                                  selectedColor: Colors.green.shade300,
                                  onSelected:
                                      isLocked
                                          ? null
                                          : (_) => _markPresent(index),
                                ),
                                const SizedBox(width: 4),
                                ChoiceChip(
                                  avatar: const Icon(Icons.cancel, size: 18, color: Colors.red),
                                  label: Text("absent").tr(),
                                  selected: status == "A",
                                  selectedColor: Colors.red.shade300,
                                  onSelected:
                                      isLocked
                                          ? null
                                          : (_) async {
                                            setState(() {
                                              attendanceList[index]["isSubmitting"] =
                                                  true;
                                              attendanceList[index]["status"] =
                                                  "A";
                                              attendanceList[index]["photo"] =
                                                  null;
                                              attendanceList[index]["location"] =
                                                  null;
                                            });

                                            await _saveAttendanceFormData(
                                              userId:
                                                  attendanceList[index]["userId"],
                                              status: "A",
                                              imagePath: null,
                                              latitude: null,
                                              longitude: null,
                                              switchedCompanyId: null,
                                            );

                                            setState(() {
                                              attendanceList[index]["isSubmitting"] =
                                                  false;
                                            });
                                          },
                                ),

                                const SizedBox(width: 4),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.swap_horiz,
                                    size: 18,
                                  ),
                                  label: Text("switch_company").tr(),
                                  onPressed:
                                      isLocked
                                          ? null
                                          : () {
                                            final userId =
                                                attendanceList[index]["userId"];
                                            _showCompanyPicker(userId);
                                          },
                                ),
                              ],
                            ),
                          ),

                          /// ✅ Selected Company Display
                          if (user["switchedCompanyName"] != null &&
                              user["switchedCompanyName"]
                                  .toString()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Company: ${user["switchedCompanyName"]}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          /// SHOW IMAGE + LOCATION
                          if (status == "P" &&
                              user["photo"] != null &&
                              user["photo"].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  if (user["imageBytes"] != null)
                                    Image.memory(
                                      user["imageBytes"],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    const SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),

                                  if (user["location"] != null)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black87,
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user["location"]["title"],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              user["location"]["address"],
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              "${user["location"]["latlng"]}   ${user["location"]["time"]}",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          if (saving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      "Saving attendance...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 30,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Opacity(
                opacity: 0.95,
                child: Transform.scale(
                  scale: 5.5, // make it bigger visually
                  child: Image.asset(
                    'assets/images/sauceit.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  "${"present".tr()}: $presentCount",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  "${"absent".tr()}: $absentCount",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// PRESENT FLOW
  /// ===============================
  Future<void> _markPresent(int index) async {
    if (attendanceList[index]["isSubmitting"] == true) return;

    setState(() {
      attendanceList[index]["isSubmitting"] = true; // 🔒 lock
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo == null) {
        attendanceList[index]["isSubmitting"] = false;
        return;
      }

      final position = await _getLocation();
      if (companyLatitude != null && companyLongitude != null) {
        final distanceMeters = _calculateDistanceMeters(
          companyLatitude!,
          companyLongitude!,
          position.latitude,
          position.longitude,
        );

        print(
          "📏 Distance from company: ${distanceMeters.toStringAsFixed(2)} meters",
        );

        if (distanceMeters > 500) {
          await _showDistancePopup(distanceMeters); // ✅ SHOW POPUP
        }
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      final bigTitle =
          "${place.locality}, ${place.administrativeArea}, ${place.country}";

      final fullAddress =
          "${place.street}, ${place.subLocality}, ${place.locality}, "
          "${place.administrativeArea} - ${place.postalCode}, ${place.country}";

      final latLng =
          "Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}";

      final time = DateFormat(
        "EEE, dd/MM/yyyy  hh:mm a",
      ).format(DateTime.now());

      final locationText = {
        "title": bigTitle,
        "address": fullAddress,
        "latlng": latLng,
        "time": time,
      };

      final originalFile = File(photo.path);

      final stampedFile = await addLocationTextOnImage(
        originalImage: originalFile,
        locationText: locationText,
      );

      setState(() {
        attendanceList[index]["status"] = "P";
        attendanceList[index]["photo"] = stampedFile.path;
        attendanceList[index]["location"] = locationText;
      });

      await _saveAttendanceFormData(
        userId: attendanceList[index]["userId"],
        status: "P",
        imagePath: stampedFile.path,
        latitude: position.latitude,
        longitude: position.longitude,
        switchedCompanyId: null,
      );
    } finally {
      setState(() {
        attendanceList[index]["isSubmitting"] = false; // 🔓 unlock
      });
    }
  }

  Future<void> _saveAttendanceFormData({
    required int userId,
    required String status,
    String? imagePath,
    double? latitude,
    double? longitude,
    int? switchedCompanyId,
  }) async {
    try {
      setState(() => saving = true); // ✅ START LOADING

      final uri = Uri.parse(
        "${AppConfig.localBaseUrl}/api/saveAttendance/${widget.companyId}",
      );

      var request = http.MultipartRequest("POST", uri);

      final payload = jsonEncode({
        "userId": userId,
        "status": status,
        "proof": null,
        "latitude": latitude, // ✅ backend BigDecimal
        "longitude": longitude, // ✅ backend BigDecimal
        "switchedCompanyId": switchedCompanyId,
      });

      request.fields["data"] = payload;

      if (status == "P" && imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath("file", imagePath));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        _showMsg("Attendance saved successfully");
        await _fetchAttendance();
      } else {
        _showMsg("Save failed: ${response.statusCode}");
      }
    } catch (e) {
      _showMsg("Save error: $e");
    } finally {
      if (mounted) {
        setState(() => saving = false); // ✅ STOP LOADING
      }
    }
  }

  /// ===============================
  /// LOCATION
  /// ===============================
  Future<Position> _getLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showMsg("Unable to get location. Please enable GPS.");
      rethrow;
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
