import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Wastage.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ProductionApproval.dart';
import 'config_loader.dart';

class FsHomePage extends StatefulWidget {
  final String companyId;
  final List<dynamic>? loginSessions; // 👈 new field for multiple subCustomers
  final String username;
  final Set<String> roles;

  const FsHomePage({
    super.key,
    required this.companyId,
    this.loginSessions,
    required this.username,
    required this.roles,
  });

  @override
  State<FsHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<FsHomePage> {
  List<dynamic> dashboardData = [];

  bool _hasRole(String role) {
    return widget.roles.contains(role);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        // "count": "2",
        "title": "order_update_approve_status",
        "image": "assets/images/Indent Alerts.png",
      },
      {
        // "count": "4",
        "title": "wastage_management",
        "image": "assets/images/Acknowledge.png",
      },
      {
        // "count": "3",
        "title": "monthly_order_summary",
        "image": "assets/images/Monthly Order.png",
      },
      {
        // "count": "5",
        "title": "qr_code",
        "image": "assets/images/qr-code.png",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Top Banner Image with main.jpg overlay
              Container(
                margin: const EdgeInsets.all(13),
                height: 230,
                clipBehavior: Clip.antiAlias,
                // ensures corners stay rounded
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔹 Zoomed Car Image Background
                    Transform.scale(
                      scale: 1.0, // zoom level (1.0 = normal)
                      child: Transform.translate(
                        offset: const Offset(-0, 0),
                        // 👈 moves image 20px to the left
                        child: Image.asset(
                          'assets/images/sauceit.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Dashboard Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () {
                        final titleKey = card["title"];

                        // Disable these cards completely
                        if (titleKey == "monthly_order_summary") {
                          return;
                        }

                        // 🔐 Approval
                        if (titleKey == "order_update_approve_status") {
                          if (!_hasRole("Approval")) {
                            _showNoAccess();
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ProductionApprovalPage(
                                    companyId: widget.companyId,
                                  ),
                            ),
                          );
                          return;
                        }

                        // 🔹 Wastage Management navigation
                        if (titleKey == "wastage_management") {
                          if (!_hasRole("Wastage")) {
                            _showNoAccess();
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => WastageMealSelectionPage(
                                    companyId: widget.companyId,
                                  ),
                            ),
                          );
                          return;
                        }

                        if (titleKey == "qr_code") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => QrCodeFeedbackScreen(
                                    username: widget.username,
                                    companyId: widget.companyId,
                                  ),
                            ),
                          );
                          return;
                        }
                      },
                      child: _buildDashboardCard(
                        // count: card["count"]!,
                        title: card["title"]!.toString().tr(),
                        imagePath: card["image"]!,
                      ),
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

  void _showNoAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You do not have access to this feature"),
        backgroundColor: Color(0xFFF15F28),
      ),
    );
  }

  Widget _buildDashboardCard({
    // required String count,
    required String title,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔹 Prevent overflows
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text section
            // Text(
            //   count,
            //   style: const TextStyle(
            //     fontSize: 34,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black,
            //   ),
            // ),
            // const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
            SizedBox(height: 20),

            Flexible(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrCodeFeedbackScreen extends StatefulWidget {
  final String companyId;
  final String username;

  const QrCodeFeedbackScreen({
    super.key,
    required this.companyId,
    required this.username,
  });

  @override
  State<QrCodeFeedbackScreen> createState() => _QrCodeFeedbackScreenState();
}

class _QrCodeFeedbackScreenState extends State<QrCodeFeedbackScreen> {
  late Future<List<Map<String, dynamic>>> _mealsFuture;
  String? _companyName; // ✅ store company name

  @override
  void initState() {
    super.initState();
    _mealsFuture = fetchUniqueMealsForQr();
  }

  Future<Map<String, int>> _fetchMealImageMap() async {
    final response = await http.get(
      Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGetMobile/list'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch meal image data");
    }

    final jsonData = json.decode(response.body);
    final List<dynamic> meals = jsonData['data'] ?? [];

    /// mealId → uomId (attachmentId)
    final Map<String, int> mealImageMap = {};

    for (final meal in meals) {
      if (meal['id'] != null && meal['uomId'] != null) {
        mealImageMap[meal['id'].toString()] = meal['uomId'];
      }
    }

    return mealImageMap;
  }

  Future<String> _fetchMealIdsForCompany() async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/companyWithMealGetMobile/${widget.companyId}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch company meals");
    }

    final jsonData = json.decode(response.body);
    final List<dynamic> meals = jsonData['data'] ?? [];

    if (meals.isEmpty) return "";

    // ✅ Extract meal IDs
    return meals.map((m) => m['id'].toString()).join(',');
  }

  Future<List<Map<String, dynamic>>> fetchUniqueMealsForQr() async {
    // final dateStr = "2025-08-12";
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    // 1️⃣ Get mealIds dynamically
    final mealIds = await _fetchMealIdsForCompany();
    if (mealIds.isEmpty) return [];

    // 2️⃣ Fetch meal → uomId map
    final mealImageMap = await _fetchMealImageMap();

    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/feedbackCompanyUserMobile/${widget.companyId}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load meals");
    }

    final jsonData = json.decode(response.body);

    // Because API returns List
    final List<dynamic> rawList =
        (jsonData is List && jsonData.isNotEmpty)
            ? jsonData.first['data'] ?? []
            : [];

    // ✅ take company name from API (first record)
    if (rawList.isNotEmpty && _companyName == null) {
      setState(() {
        _companyName = rawList.first['companyName'];
      });
    }

    // 4️⃣ Keep UNIQUE meals
    final Map<String, Map<String, dynamic>> uniqueMeals = {};

    for (final item in rawList) {
      final mealId = item['mealId'].toString();

      if (!uniqueMeals.containsKey(mealId)) {
        uniqueMeals[mealId] = {
          "mealId": item['mealId'],
          "mealName": item['mealName'],
          // ✅ uomId as attachmentId
          "attachmentId": mealImageMap[mealId],
          "imageBytes": null,
        };
      }
    }

    // 5️⃣ Load images using uomId
    await Future.wait(
      uniqueMeals.values.map((meal) async {
        final attachmentId = meal['attachmentId'];
        if (attachmentId != null && attachmentId != 0) {
          try {
            final imgRes = await http.get(
              Uri.parse(
                '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
              ),
            );
            if (imgRes.statusCode == 200) {
              meal['imageBytes'] = imgRes.bodyBytes;
            }
          } catch (_) {}
        }
      }),
    );

    return uniqueMeals.values.toList();
  }

  void _showQrDialog(BuildContext context, int mealId, String mealName) {
    // const String url =
    //     "http://fsx-prod-alb-web-1580089941.us-east-1.elb.amazonaws.com/";

    final String url =
        "http://fsx-prod-alb-web-1580089941.us-east-1.elb.amazonaws.com/"
        "app/${widget.companyId}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text("scan".tr(), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔗 URL TEXT
              SelectableText(
                _companyName ?? mealName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              // 🔳 QR CODE
              QrImageView(data: url, size: 200, backgroundColor: Colors.white),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  // 🌐 OPEN
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: Text("open".tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF15F28),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(url);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),

                  // 📋 COPY
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text("copy".tr()),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link copied")),
                      );
                    },
                  ),

                  // 🖨 PRINT
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: Text("print".tr()),
                    onPressed: () {
                      _printQrCode(url, mealName);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printQrCode(String url, String mealName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  "Scan to Open Website",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  mealName,
                  style: const pw.TextStyle(fontSize: 18),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 20),

                // 🔳 QR CODE
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: url,
                  width: 200,
                  height: 200,
                ),

                pw.SizedBox(height: 20),

                // 🔗 URL
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "qr_scanner".tr(),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Text(
              "$dateStr • ${_companyName ?? ''}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mealsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No meals found"));
              }

              final meals = snapshot.data!;

              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1, // ✅ Single column
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9, // adjust height if needed
                        ),

                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];

                      return Center(
                        child: SizedBox(
                          width: 260, // ✅ control card width
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🖼 Meal Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      meal['imageBytes'] != null
                                          ? Image.memory(
                                            meal['imageBytes'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.fastfood,
                                              size: 48,
                                            ),
                                          ),
                                ),

                                const SizedBox(height: 12),

                                // 🍽 Meal Name
                                Text(
                                  meal['mealName'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // 🔳 QR BUTTON
                                InkWell(
                                  onTap: () {
                                    _showQrDialog(
                                      context,
                                      meal['mealId'],
                                      meal['mealName'],
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.qr_code,
                                      color: Color(0xFFF15F28),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
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
    );
  }
}
