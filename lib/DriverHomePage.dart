import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config_loader.dart';
import 'api_service.dart';

class DriverHomePage extends StatefulWidget {
  final String driverId;

  const DriverHomePage({super.key, required this.driverId});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  List<dynamic> dashboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/vehicleDashboard/${widget.driverId}',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          dashboardData = jsonData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        print('❌ Failed to load dashboard: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('⚠️ Error fetching dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getImageForLabel(String labelKey) {
    final normalizedKey = labelKey.toLowerCase().replaceAll(
      " ",
      "_",
    ); // normalize text

    switch (normalizedKey) {
      case "upcoming_trips":
        return "assets/images/upcoming.png";
      case "completed_trips":
        return "assets/images/completed.png";
      case "total_kilometer":
        return "assets/images/kilometer.png";
      case "breakdown":
        return "assets/images/breakdown.png";
      default:
        return "assets/images/kilometer.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      // 🔹 Banner Section
                      Container(
                        margin: const EdgeInsets.all(16),
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/car.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Transform.scale(
                                scale: 1.3,
                                child: Image.asset(
                                  'assets/images/man.png',
                                  width: 280,
                                  height: 190,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              top: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Route Thala".tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "time".tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(14),
                        height: 110,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(0),
                              child: Transform.rotate(
                                angle: -0.2,
                                child: Image.asset(
                                  'assets/images/bulb.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "zero".tr(),
                                    style: TextStyle(
                                      color: Color(0xFF010440),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "consistent".tr(),
                                    style: TextStyle(
                                      color: Color(0xFF010440),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Dynamic Dashboard Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dashboardData.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 19,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final card = dashboardData[index];
                            final count = card["count"].toString();
                            final titleKey = card["label"].toString();

                            final normalizedKey = titleKey
                                .toLowerCase()
                                .replaceAll(" ", "_");
                            final imagePath = _getImageForLabel(titleKey);

                            print(
                              "🔑 API Label: $titleKey -> Normalized: $normalizedKey",
                            );

                            return _buildDashboardCard(
                              count: count,
                              title: normalizedKey.tr(),
                              imagePath: imagePath,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String count,
    required String title,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // important
          children: [
            // Wrap text section in Expanded with SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
