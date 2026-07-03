import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ViewEditOrders.dart';
import 'config_loader.dart';
import 'package:intl/intl.dart'; // <-- Add this import at the top

class FsOrdersPage extends StatefulWidget {
  final String companyId;
  final List<dynamic>? loginSessions; // 👈 new field for multiple subCustomers
  final String username;
  final bool isFsCustomer; // 👈 ADD THIS

  const FsOrdersPage({
    super.key,
    required this.companyId,
    this.loginSessions,
    required this.username,
    this.isFsCustomer = false,
  });

  @override
  State<FsOrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<FsOrdersPage> {
  final PageController _pageController = PageController();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<TextEditingController> _mealCountControllers = [];

  List<dynamic> feedbackMeals = [];
  List<dynamic> mealTypes = [];
  bool _isLoading = true;
  bool _feedbackAlreadySubmitted = false;
  String _feedbackMessage = "";
  String _mealIdsForQr = "";

  bool get _hasSubCustomers => _subCustomersList.isNotEmpty;
  List<TextEditingController> _subCustomerControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchSubCustomers();
  }

  List<dynamic> _subCustomersList = [];

  Future<void> _fetchSubCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/subCustomerMasterAllGetMobile/list/${widget.companyId}',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final allSubs = jsonData['data'] ?? [];

        // ✅ Extract all subCustomerIds from loginSessions
        final loginSessionSubIds =
            widget.loginSessions
                ?.map((e) => e['subCustomerId'].toString())
                .toList() ??
            [];

        // ✅ Filter only the sub-customers from loginSessions
        if (loginSessionSubIds.isNotEmpty) {
          _subCustomersList =
              allSubs
                  .where(
                    (sub) => loginSessionSubIds.contains(sub['id'].toString()),
                  )
                  .toList();
        } else {
          // Fallback: show all if no login sessions
          _subCustomersList = allSubs;
        }

        // ✅ Initialize controllers for each sub-customer
        _subCustomerControllers =
            _subCustomersList
                .map((sub) => TextEditingController(text: '0'))
                .toList();

        setState(() {});
      } else {
        print("Failed to fetch sub-customers: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sub-customers: $e");
    }
  }

  Future<void> _loadData() async {
    try {
      // 1️⃣ Fetch meals/items without images
      await Future.wait([_fetchMeals(fetchImages: false)]);

      // 2️⃣ Load feedback
      await _fetchFeedbackData();

      // 3️⃣ Show UI immediately
      setState(() => _isLoading = false);
      _fetchMealImages();
      // 4️⃣ Download images in the background (one by one)
      _fetchItemImagesFromAttachments();
    } catch (e) {
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _fetchMealImages() async {
    for (var meal in mealTypes) {
      final attachmentId = meal['attachmentId'];
      if (attachmentId != null) {
        try {
          final imageResponse = await http.get(
            Uri.parse(
              '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
            ),
          );
          if (imageResponse.statusCode == 200) {
            if (!mounted) return;
            setState(() {
              meal['imageBytes'] = imageResponse.bodyBytes;
            });
          }
        } catch (e) {
          print("⚠️ Failed to load meal image for $attachmentId: $e");
        }
      }
    }
  }

  Future<void> _fetchMeals({bool fetchImages = true}) async {
    try {
      // 1️⃣ Get company-specific meals
      final companyResponse = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/companyWithMealGetMobile/${widget.companyId}',
        ),
      );

      if (companyResponse.statusCode != 200) {
        print('❌ Failed to fetch company meals.');
        return;
      }

      final companyJson = json.decode(companyResponse.body);
      final List<dynamic> companyMeals = companyJson['data'] ?? [];

      // 2️⃣ Get all meals (for mapping mealId → attachment uomId)
      final mealResponse = await http.get(
        Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGetMobile/list'),
      );

      if (mealResponse.statusCode != 200) {
        print('❌ Failed to fetch all meals.');
        return;
      }

      final mealJson = json.decode(mealResponse.body);
      final List<dynamic> allMeals = mealJson['data'] ?? [];

      // 3️⃣ Merge both results based on mealId (company.id == allMeals.id)
      for (var meal in companyMeals) {
        final matchingMeal = allMeals.firstWhere(
          (m) => m['id'] == meal['id'],
          orElse: () => {},
        );

        if (matchingMeal.isNotEmpty && matchingMeal['uomId'] != null) {
          // Attach the uomId (which is actually attachment ID)
          meal['attachmentId'] = matchingMeal['uomId'];
        }
      }

      // 4️⃣ Save merged list
      setState(() {
        mealTypes = companyMeals;
      });

      _mealCountControllers =
          mealTypes
              .map(
                (meal) => TextEditingController(
                  text: (meal['mainCount'] ?? 0).toString(),
                ),
              )
              .toList();

      // 5️⃣ Optionally load images for each attachmentId
      if (fetchImages) {
        await Future.wait(
          mealTypes.map((meal) async {
            final attachmentId = meal['attachmentId'];
            if (attachmentId != null) {
              try {
                final imageResponse = await http.get(
                  Uri.parse(
                    '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
                  ),
                );
                if (imageResponse.statusCode == 200) {
                  setState(() {
                    meal['imageBytes'] = imageResponse.bodyBytes;
                  });
                }
              } catch (e) {
                print("⚠️ Failed to load meal image for $attachmentId: $e");
              }
            }
          }),
        );
      }

      print("✅ Meals loaded successfully for company ${widget.companyId}");
    } catch (e) {
      print("⚠️ Error fetching meals: $e");
    }
  }

  void _goToNext() {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("please".tr())));
      return;
    }

    final List<String> allowedSubCustomers = [];

    if (widget.loginSessions != null) {
      for (var s in widget.loginSessions!) {
        if (s['subCustomerId'] != null) {
          allowedSubCustomers.add(s['subCustomerId'].toString());
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ViewEditOrders(
              companyId: widget.companyId,
              fromDate: _fromDate!,
              toDate: _toDate!,
              allowedSubCustomerIds: allowedSubCustomers, // 👈 pass list
              isFsCustomer: widget.isFsCustomer
            ),
      ),
    );
  }

  Future<void> _fetchItemImagesFromAttachments() async {
    for (final meal in feedbackMeals) {
      for (final item in meal["items"]) {
        final int attachmentId =
            (item["attachmentId"] != null && item["attachmentId"] != 0)
                ? item["attachmentId"]
                : item["categoryAttachmentId"];

        if (attachmentId == null || attachmentId == 0) continue;

        try {
          final response = await http.get(
            Uri.parse(
              '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
            ),
          );

          if (response.statusCode == 200) {
            setState(() {
              item["imageBytes"] = response.bodyBytes;
            });
          }
        } catch (e) {
          print("Failed to load image for attachmentId $attachmentId: $e");
        }
      }
    }
  }

  Future<void> _fetchFeedbackData() async {
    if (mealTypes.isEmpty) return; // Ensure meals are fetched first

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    // Extract meal IDs dynamically
    final mealIds = mealTypes.map((meal) => meal['id'].toString()).join(',');

    _mealIdsForQr = mealIds;

    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/menuPlanForMobile/'
        '$dateStr/$dateStr/${widget.companyId}/$mealIds/${widget.username}',
      ),
    );

    try {
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // ✅ Check API message
        final message = jsonData['status']?['message'];

        if (message == "Feedback already submitted") {
          setState(() {
            _feedbackAlreadySubmitted = true;
            _feedbackMessage = message;
            _isLoading = false;
          });
          return;
        }

        final List<dynamic> rawList = jsonData['data'];

        final Map<String, Map<String, dynamic>> groupedMeals = {};

        for (var item in rawList) {
          final mealId = item['mealId'].toString();

          groupedMeals.putIfAbsent(mealId, () {
            return {
              "companyId": item['companyId'],
              "companyName": item['companyName'],
              "mealId": item['mealId'],
              "mealName": item['mealName'],
              "date": item['date'],
              "items": [],
            };
          });

          groupedMeals[mealId]!["items"].add({
            "itemId": item["itemId"],
            "itemName": item["itemName"],
            "gram": item["gram"],
            "attachmentId": item["attachmentId"],
            "categoryAttachmentId": item["categoryAttachmentId"],
            "imageBytes": null,
            "rating": 0,
          });
        }

        setState(() {
          feedbackMeals = groupedMeals.values.toList();
          _feedbackAlreadySubmitted = false;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load feedback data");
      }
    } catch (e) {
      print("Error loading feedback: $e");
      setState(() => _isLoading = false);
    }
  }

  // void _showQrDialog(BuildContext context) {
  //   // const String url =
  //   //     "http://fsx-prod-alb-web-1580089941.us-east-1.elb.amazonaws.com/";
  //
  //   final String url =
  //       "http://fsx-prod-alb-web-1580089941.us-east-1.elb.amazonaws.com/"
  //       "app/${widget.companyId}/$_mealIdsForQr";
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         title: const Text("Scan or Open Link", textAlign: TextAlign.center),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // 🔳 QR CODE
  //             QrImageView(data: url, size: 200, backgroundColor: Colors.white),
  //
  //             const SizedBox(height: 12),
  //
  //             // 🔗 URL TEXT
  //             // SelectableText(
  //             //   url,
  //             //   textAlign: TextAlign.center,
  //             //   style: const TextStyle(fontSize: 12),
  //             // ),
  //
  //             const SizedBox(height: 16),
  //
  //             Wrap(
  //               spacing: 10,
  //               runSpacing: 10,
  //               alignment: WrapAlignment.center,
  //               children: [
  //                 // 🌐 OPEN
  //                 ElevatedButton.icon(
  //                   icon: const Icon(Icons.open_in_browser),
  //                   label: Text("open".tr()),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Color(0xFFF15F28),
  //                   ),
  //                   onPressed: () async {
  //                     Navigator.pop(context);
  //                     final uri = Uri.parse(url);
  //                     await launchUrl(
  //                       uri,
  //                       mode: LaunchMode.externalApplication,
  //                     );
  //                   },
  //                 ),
  //
  //                 // 📋 COPY
  //                 OutlinedButton.icon(
  //                   icon: const Icon(Icons.copy),
  //                   label: Text("copy".tr()),
  //                   onPressed: () {
  //                     Clipboard.setData(ClipboardData(text: url));
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(content: Text("Link copied")),
  //                     );
  //                   },
  //                 ),
  //
  //                 // 🖨 PRINT
  //                 OutlinedButton.icon(
  //                   icon: const Icon(Icons.print),
  //                   label: Text("print".tr()),
  //                   onPressed: () {
  //                     _printQrCode(url);
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
  //
  // Future<void> _printQrCode(String url) async {
  //   final pdf = pw.Document();
  //
  //   pdf.addPage(
  //     pw.Page(
  //       build: (context) {
  //         return pw.Center(
  //           child: pw.Column(
  //             mainAxisSize: pw.MainAxisSize.min,
  //             children: [
  //               pw.Text(
  //                 "Scan to Open Website",
  //                 style: pw.TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //
  //               pw.SizedBox(height: 20),
  //
  //               // 🔳 QR CODE
  //               pw.BarcodeWidget(
  //                 barcode: pw.Barcode.qrCode(),
  //                 data: url,
  //                 width: 200,
  //                 height: 200,
  //               ),
  //
  //               pw.SizedBox(height: 20),
  //
  //               // 🔗 URL
  //               // pw.Text(
  //               //   url,
  //               //   style: const pw.TextStyle(fontSize: 12),
  //               //   textAlign: pw.TextAlign.center,
  //               // ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  //
  //   await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  // }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Widget _buildDateField(DateTime? date, String placeholder) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date == null
                ? placeholder
                : '${date.day}-${date.month}-${date.year}',
            style: const TextStyle(fontSize: 15),
          ),
          const Icon(Icons.calendar_today, color: Color(0xFFF15F28)),
        ],
      ),
    );
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _nextPage() {
    if (_pageController.page! < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitFeedback() async {
    try {
      final List<Map<String, dynamic>> payload = [];

      for (var meal in feedbackMeals) {
        for (var item in meal['items']) {
          payload.add({
            "companyId": meal['companyId'],
            "companyName": meal['companyName'],
            "mealId": meal['mealId'],
            "mealName": meal['mealName'],
            "itemId": item['itemId'],
            "itemName": item['itemName'],
            "responseValue": item['rating'], // ⭐ rating selected
            "consumed": 1,
            "customerName": widget.username, // 🔹 replace dynamically if needed
          });
        }
      }

      final response = await http.post(
        Uri.parse('${AppConfig.localBaseUrl}/api/createFeedbackForMobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status']['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Feedback submitted successfully")),
          );

          // 👉 Navigate to next page
          _nextPage();
        } else {
          throw Exception(jsonData['status']['message']);
        }
      } else {
        throw Exception("Failed to submit feedback");
      }
    } catch (e) {
      print("Feedback submit error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  Future<bool> _hasOrderData(DateTime from, DateTime to) async {
    final fromStr =
        "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
    final toStr =
        "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/orderListMobile/$fromStr/$toStr/${widget.companyId}',
      ),
    );

    if (response.statusCode == 404) return false;

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch order data");
    }

    final jsonData = json.decode(response.body);
    final List data = jsonData['data'] ?? [];

    return data.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final previousDate = DateTime.now().subtract(const Duration(days: 1));
    // final previousDateStr =
    //     "${previousDate.day}-${previousDate.month}-${previousDate.year}";
    final previousDateStr = DateFormat(
      'd MMM yyyy',
    ).format(previousDate); // ✅ 18 Oct 2025 format

    // Group meals by type
    final Map<String, List<dynamic>> mealsByType = {};
    for (var meal in feedbackMeals) {
      final type = meal['mealType'] ?? '';
      if (!mealsByType.containsKey(type)) mealsByType[type] = [];
      mealsByType[type]!.add(meal);
    }

    bool _isAtLeastOneItemRatedPerMeal() {
      for (final entry in mealsByType.entries) {
        final meals = entry.value;

        for (final meal in meals) {
          final List items = meal['items'] ?? [];

          // ❌ No item in this meal has rating > 0
          final hasRatedItem = items.any(
                (item) => (item['rating'] ?? 0) > 0,
          );

          if (!hasRatedItem) {
            return false; // 🚫 stop immediately
          }
        }
      }
      return true; // ✅ all meals valid
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: [
              // Page 1: Feedback
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with back arrow and Feedback title
                    Row(
                      children: [
                        const SizedBox(width: 105),
                        // space between icon and text
                        Text(
                          "feedback".tr(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 34),
                        TextButton(
                          onPressed: () {
                            _nextPage(); // 👉 move to next page
                          },
                          child: Text(
                            "skip".tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF15F28),
                            ),
                          ),
                        ),
                        //     InkWell(
                        //       onTap: () {
                        //         _showQrDialog(context);
                        //       },
                        //       child: Container(
                        //         padding: const EdgeInsets.all(12),
                        //         decoration: BoxDecoration(
                        //           color: Colors.white,
                        //           shape: BoxShape.circle,
                        //           boxShadow: const [
                        //             BoxShadow(color: Colors.black26, blurRadius: 6),
                        //           ],
                        //         ),
                        //         child: const Icon(
                        //           Icons.qr_code,
                        //           color: Color(0xFFF15F28),
                        //           size: 26,
                        //         ),
                        //         // ✅ Proceed Button
                        //       ),
                        //     ),
                      ],
                    ),
                    Center(
                      child: Text(
                        "$previousDateStr",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _feedbackAlreadySubmitted
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 12),
                                    Text(
                                      "feedback_submitted".tr(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : feedbackMeals.isEmpty
                              ? Center(child: Text("no_feedbacks".tr()))
                              : ListView(
                                children:
                                    mealsByType.entries.map((entry) {
                                      final meals = entry.value;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Text(
                                          // mealType,
                                          // style: const TextStyle(
                                          //   fontSize: 2,
                                          //   fontWeight: FontWeight.bold,
                                          //   color: Color(0xFFF15F28),
                                          // ),
                                          // ),
                                          const SizedBox(height: 5),
                                          ...meals.map((meal) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    meal['mealName'] ??
                                                        "Unknown",
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  if (meal['items'] != null)
                                                    ...meal['items'].map<
                                                      Widget
                                                    >((item) {
                                                      // Find item in itemTypes by id
                                                      final itemImageBytes =
                                                          item['imageBytes'];

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 10,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            // Display image if available, else fallback container
                                                            itemImageBytes !=
                                                                    null
                                                                ? ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                  child: Image.memory(
                                                                    itemImageBytes,
                                                                    width: 80,
                                                                    height: 80,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                )
                                                                : Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colors
                                                                            .grey[300],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .fastfood,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                item['itemName'] ??
                                                                    "Unknown",
                                                              ),
                                                            ),
                                                            // Star rating row
                                                            Row(
                                                              children: List.generate(5, (
                                                                i,
                                                              ) {
                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    setState(() {
                                                                      item['rating'] =
                                                                          i + 1;
                                                                    });
                                                                  },
                                                                  child: Icon(
                                                                    Icons.star,
                                                                    // <-- IconData goes here
                                                                    color:
                                                                        (item['rating'] ??
                                                                                    0) >
                                                                                i
                                                                            ? Color(
                                                                              0xFFF15F28,
                                                                            )
                                                                            : Colors.grey,
                                                                    size: 22,
                                                                  ),
                                                                );
                                                              }),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      );
                                    }).toList(),
                              ),
                    ),

                    SizedBox(height: 20), // add space above button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        // moves button up from bottom
                        child: ElevatedButton(
                          onPressed: () {
                            if (_feedbackAlreadySubmitted) {
                              _nextPage();
                              return;
                            }

                            // ❌ Validate ratings
                            final isValid = _isAtLeastOneItemRatedPerMeal();

                            if (!isValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please give feedback for all meals",
                                  ),
                                  backgroundColor: Color(0xFFF15F28),
                                ),
                              );
                              return; // 🚫 stop here
                            }

                            // ✅ Valid → submit feedback
                            _submitFeedback();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF15F28),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "proceed_a_new_order".tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 10), // optional space below
                  ],
                ),
              ),

              // Padding(
              //   padding: const EdgeInsets.all(20),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       // Header Row with back arrow and Feedback title
              //       Row(
              //         children: [
              //           const SizedBox(width: 105),
              //           // space between icon and text
              //           const Text(
              //             'Feedback',
              //             style: TextStyle(
              //               fontSize: 24,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔙 Back button + Title
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        // space between icon and text
                        Text(
                          "delivery_date".tr(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 40),
                        InkWell(
                          onTap: () {
                            _nextPage();
                          },
                          child: Row(
                            children: const [
                              Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFF15F28),
                                size: 30,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Add",
                                style: TextStyle(
                                  color: Color(0xFFF15F28),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // 🔹 From Date
                    Text(
                      "from_date".tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFromDate,
                      child: _buildDateField(_fromDate, "select_date".tr()),
                    ),

                    const SizedBox(height: 24),

                    // 🔹 To Date
                    Text(
                      "to_date".tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickToDate,
                      child: _buildDateField(_toDate, "select_date".tr()),
                    ),

                    const SizedBox(height: 170),

                    // 🔸 Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_fromDate == null || _toDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("please".tr()),
                                backgroundColor: Color(0xFFF15F28),
                              ),
                            );
                            return;
                          }

                          try {
                            final hasData = await _hasOrderData(
                              _fromDate!,
                              _toDate!,
                            );

                            if (hasData) {
                              // ✅ Data exists → proceed with selected dates
                              _goToNext();
                            } else {
                              // ✅ No data → fallback to existing delivery date logic
                              _nextPage();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("⚠️ Error: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF15F28),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "submit".tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page 3: Place Order
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Row for back arrow + centered title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (_pageController.page! > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "place_an_order".tr(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    // Date range display
                    Text(
                      _fromDate != null && _toDate != null
                          ? '${DateFormat("d MMM yyyy").format(_fromDate!)}  -  ${DateFormat("d MMM yyyy").format(_toDate!)}'
                          : 'Select Date Range',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    // Meal List (scrollable)
                    Expanded(
                      child: ListView.builder(
                        itemCount: mealTypes.length,
                        itemBuilder: (context, index) {
                          final meal = mealTypes[index];
                          final imageBytes = meal['imageBytes'];
                          final isExpanded = meal['isExpanded'] ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Meal Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    meal['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: const Color(0xFFF15F28),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        meal['isExpanded'] = !isExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 🔸 Meal Image + Count Field (READ-ONLY total)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child:
                                        imageBytes != null
                                            ? Image.memory(
                                              imageBytes,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              height: 150,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: SizedBox(
                                      width: 80,
                                      height: 40,
                                      child: TextField(
                                        controller:
                                            _mealCountControllers[index],

                                        // FIXED 🔥
                                        readOnly: _hasSubCustomers,

                                        onChanged: (value) {
                                          final count =
                                              int.tryParse(value) ?? 0;
                                          meal['mainCount'] = count;

                                          if (!_hasSubCustomers) {
                                            meal['mealCount'] = count;
                                          }

                                          setState(() {});
                                        },

                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Count',
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          fillColor: Colors.white.withOpacity(
                                            0.9,
                                          ),
                                          filled: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 🔽 Sub-customer List with Editable Counts
                              // Sub-customer List with Editable Counts
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild:
                                    _hasSubCustomers
                                        ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 15),
                                            Text(
                                              "Sub Customers for ${meal['name']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF7F4),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              child: ListView.separated(
                                                itemCount:
                                                    _subCustomersList.length,
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                separatorBuilder:
                                                    (_, __) => Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                itemBuilder: (
                                                  context,
                                                  subIndex,
                                                ) {
                                                  final sub =
                                                      _subCustomersList[subIndex];
                                                  final controller =
                                                      _subCustomerControllers[subIndex];

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            sub['name'] ?? '',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 70,
                                                          child: TextField(
                                                            controller:
                                                                controller,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration: InputDecoration(
                                                              isDense: true,
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 6,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                            ),
                                                            onChanged: (value) {
                                                              _recalculateMealCount(
                                                                index,
                                                              );
                                                            },
                                                          ),

                                                          // onChanged: (value) {
                                                          //       sub['orderCount'] =
                                                          //           int.tryParse(
                                                          //             value,
                                                          //           ) ??
                                                          //           0;
                                                          //
                                                          //       // Update meal's subCustomers list
                                                          //       meal['subCustomers'] =
                                                          //           _subCustomersList;
                                                          //
                                                          //       // Update total meal count dynamically for this meal
                                                          //       if (_hasSubCustomers) {
                                                          //         // Sum of sub customers
                                                          //         meal['mealCount'] =
                                                          //             _subCustomersList.fold<
                                                          //               int
                                                          //             >(
                                                          //               0,
                                                          //               (
                                                          //                 sum,
                                                          //                 s,
                                                          //               ) =>
                                                          //                   sum +
                                                          //                   (s['orderCount']
                                                          //                           as int? ??
                                                          //                       0),
                                                          //             );
                                                          //       } else {
                                                          //         // No sub customers → use main meal count only
                                                          //         meal['mealCount'] =
                                                          //             int.tryParse(
                                                          //               meal['mainCount']
                                                          //                       ?.toString() ??
                                                          //                   "0",
                                                          //             ) ??
                                                          //             0;
                                                          //       }
                                                          //
                                                          //       setState(
                                                          //         () {},
                                                          //       ); // Refresh UI
                                                          //     },
                                                          //   ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text(
                                            "No sub-customers",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                crossFadeState:
                                    isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 300),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        if (_fromDate == null || _toDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select both From and To dates.',
                              ),
                              backgroundColor: Color(0xFFF15F28),
                            ),
                          );
                          return;
                        }

                        final enteredMeals =
                            mealTypes
                                .where((meal) => (meal['mealCount'] ?? 0) > 0)
                                .map(
                                  (meal) => {
                                    'id': meal['id'],
                                    'name': meal['name'],
                                    'mealCount': meal['mealCount'],
                                    "subCustomers":
                                        (meal['subCustomers'] ?? [])
                                            .map(
                                              (s) => {
                                                "id": s['id'],
                                                "name": s['name'],
                                                "orderCount":
                                                    s['orderCount'] ?? 0,
                                              },
                                            )
                                            .toList(),
                                  },
                                )
                                .toList();
                        print("📋 Entered Meals JSON: $enteredMeals");
                        if (enteredMeals.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter at least one meal count.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        // Format dates
                        String fromDateStr =
                            "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
                        String toDateStr =
                            "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";

                        // Define all days (0–6 means Sunday–Saturday)
                        List<int> days = [];
                        DateTime current = _fromDate!;
                        while (current.isBefore(
                          _toDate!.add(const Duration(days: 1)),
                        )) {
                          days.add(current.weekday % 7);
                          // Flutter's weekday: Monday=1..Sunday=7 → backend expects 0=Sunday..6=Saturday
                          current = current.add(const Duration(days: 1));
                        }

                        // Prepare JSON body
                        final body = {
                          "companyId": int.parse(widget.companyId),
                          "meals": enteredMeals,
                          "orderDate": fromDateStr,
                          "toDate": toDateStr,
                          "day": days,
                        };

                        print("📦 Sending order data: $body");

                        try {
                          final response = await http.post(
                            Uri.parse(
                              '${AppConfig.localBaseUrl}/api/createOrderForAllMobile',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode(
                              body,
                            ), // make sure to encode the request body properly
                          );

                          final data = json.decode(response.body);

                          if (response.statusCode == 201 &&
                              data['status']['code'] == 201) {
                            // ✅ Move to “Order Placed” screen instead of new page
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else if (data['status']['code'] == 409) {
                            // ⚠️ Order already exists
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['status']['message'] ??
                                      "Order already exists",
                                ),
                                backgroundColor: Color(0xFFF15F28),
                              ),
                            );
                          } else {
                            // ❌ API error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['status']?['message'] ??
                                      'Failed to create order. Please try again.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          print("❌ Error placing order: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error connecting to server. Please try again.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15F28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "place_order".tr(),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    // Info text below button
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.red),
                          SizedBox(width: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "place_before".tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "4pm".tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Page 3: Order Placed
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "order_placed".tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "thank_you".tr(),
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        // ✅ Optionally go back to first screen
                        _pageController.jumpToPage(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15F28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back to Indent',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Page 3: Order Placed
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

  void _recalculateMealCount(int mealIndex) {
    int total = 0;

    // ADD — sum subcustomer controllers
    for (var controller in _subCustomerControllers) {
      total += int.tryParse(controller.text) ?? 0;
    }

    // update UI
    setState(() {
      _mealCountControllers[mealIndex].text = total.toString();
      mealTypes[mealIndex]['mainCount'] = total;
      mealTypes[mealIndex]['mealCount'] = total;
    });
  }
}
