import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'config_loader.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LabelMealSelectionPage extends StatefulWidget {
  final String companyId;
  final List<dynamic>? loginSessions;

  const LabelMealSelectionPage({
    super.key,
    required this.companyId,
    this.loginSessions,
  });

  @override
  State<LabelMealSelectionPage> createState() => _LabelMealSelectionPageState();
}

class _LabelMealSelectionPageState extends State<LabelMealSelectionPage> {
  DateTime? selectedDate;
  List<dynamic> meals = [];
  dynamic selectedMeal;

  bool loadingMeals = true;

  @override
  void initState() {
    super.initState();
    fetchMeals();
  }

  Future<void> fetchMeals() async {
    try {
      final url =
          "${AppConfig.localBaseUrl}/api/companyWithMealGetMobile/${widget.companyId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          meals = data["data"];
          loadingMeals = false;
        });
      } else {
        setState(() => loadingMeals = false);
      }
    } catch (e) {
      setState(() => loadingMeals = false);
    }
  }

  Future<void> pickDate() async {
    DateTime now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("generate_labels").tr(),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 BACKGROUND WATERMARK
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Transform.scale(
                scale: 1.0,
                child: Image.asset(
                  'assets/images/watermark.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 🔹 MAIN CONTENT
          Padding(
            padding: const EdgeInsets.all(14),
            child:
                loadingMeals
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),

                        // DATE PICKER
                        Text(
                          "select_date".tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),

                        InkWell(
                          onTap: pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedDate == null
                                      ? "choose_date".tr()
                                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const Icon(Icons.calendar_month),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // MEAL DROPDOWN
                        Text(
                          "select_meal".tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),

                        DropdownButtonFormField(
                          decoration: InputDecoration(
                            hintText: "choose_meal".tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          value: selectedMeal,
                          items:
                              meals.map((meal) {
                                return DropdownMenuItem(
                                  value: meal,
                                  child: Text(meal["name"]),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => selectedMeal = value);
                          },
                        ),
                        const SizedBox(height: 50),

                        // NEXT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFFF15F28),
                            ),
                            onPressed: () {
                              if (selectedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please choose a date"),
                                  ),
                                );
                                return;
                              }
                              if (selectedMeal == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please choose a meal"),
                                  ),
                                );
                                return;
                              }

                              final formattedDate =
                                  "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CameronPage(
                                        companyId: widget.companyId,
                                        mealId: selectedMeal["id"],
                                        date: formattedDate,
                                        mealName: selectedMeal["name"],
                                        loginSessions: widget.loginSessions,
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              "next".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),

          // ⭐ SAUCEIT PNG ON BOTTOM-RIGHT
          Positioned(
            bottom: 3,
            right: 30,
            child: Opacity(
              opacity: 0.95,
              child: Transform.scale(
                scale: 5.5, // bigger without touching width/height
                child: Image.asset(
                  'assets/images/sauceit.png',
                  width: 30,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameronPage extends StatefulWidget {
  final String companyId;
  final int mealId;
  final String date;
  final String mealName;
  final List<dynamic>? loginSessions;

  const CameronPage({
    super.key,
    required this.companyId,
    required this.mealId,
    required this.date,
    required this.mealName,
    this.loginSessions,
  });

  @override
  State<CameronPage> createState() => _CameronPageState();
}

class _CameronPageState extends State<CameronPage> {
  late Future<List<dynamic>?> cameronFuture;
  late Future<List<dynamic>> vehicleFuture;
  List<dynamic> vehicles = [];

  @override
  void initState() {
    super.initState();
    cameronFuture = fetchCameronData();
    vehicleFuture = fetchVehicles();
  }

  // ================= API =================
  Future<List<dynamic>?> fetchCameronData() async {
    final url =
        "${AppConfig.localBaseUrl}/api/mealReadyTrackerCompanyMobile/${widget.date}/${widget.mealId}/${widget.companyId}/Gcc";

    final response = await http.get(Uri.parse(url));
    debugPrint("response body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)["data"];

      // ✅ Make sure loginSessions are current
      final allowedSubCustomerIds =
          widget.loginSessions?.map((e) => e["subCustomerId"]).toSet() ?? {};

      debugPrint("Allowed subCustomerIds: $allowedSubCustomerIds");

      for (var company in data) {
        final mappings = company["mapping"] as List;
        company["mapping"] =
            mappings
                .where(
                  (m) => allowedSubCustomerIds.contains(m["subCustomerId"]),
                )
                .toList();
      }

      // Remove companies with no allowed mappings
      data = data.where((c) => (c["mapping"] as List).isNotEmpty).toList();

      debugPrint(
        "Filtered subCustomers: ${data.map((c) => c["mapping"]).toList()}",
      );

      return data;
    }
    return null;
  }

  Future<List<dynamic>> fetchVehicles() async {
    final url = "${AppConfig.localBaseUrl}/api/vehicleAllGetByKitchen";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["data"];
    }
    return [];
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "cameron_box".tr(),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Text(
              "${widget.mealName} • ${widget.date}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// 🔹 MAIN LIST
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([cameronFuture, vehicleFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("No data found"));
                }

                final companies = snapshot.data![0] as List<dynamic>;
                vehicles = snapshot.data![1] as List<dynamic>;

                // ✅ Check if filtered companies list is empty
                if (companies.isEmpty) {
                  return const Center(child: Text("No data found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: companies.length,
                  itemBuilder: (_, cIndex) {
                    final company = companies[cIndex];
                    final mappings = company["mapping"] as List;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// COMPANY NAME (CENTER)
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              company["companyName"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        ...mappings
                            .where((m) => (m["items"] as List).isNotEmpty)
                            .map((mapping) {
                              final items = mapping["items"] as List;

                              final int kitchenId = items.first["kitchenId"];

                              final List<dynamic> filteredVehicles =
                                  vehicles
                                      .where((v) => v["uomId"] == kitchenId)
                                      .toList();

                              final int? selectedVehicleId =
                                  filteredVehicles.any(
                                        (v) => v["id"] == mapping["vehicleId"],
                                      )
                                      ? mapping["vehicleId"]
                                      : null;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${mapping["subCustomerName"]} • PAX: ${mapping["paxCount"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  /// VEHICLE DROPDOWN
                                  DropdownButtonFormField<int>(
                                    value: selectedVehicleId,
                                    isExpanded: true,
                                    items:
                                        filteredVehicles
                                            .map<DropdownMenuItem<int>>((v) {
                                              return DropdownMenuItem<int>(
                                                value: v["id"],
                                                child: Text(v["name"]),
                                              );
                                            })
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        mapping["vehicleId"] = value;
                                        final selected = filteredVehicles
                                            .firstWhere(
                                              (v) => v["id"] == value,
                                            );
                                        mapping["vehicleName"] =
                                            selected["name"];
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: "vehicle".tr(),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  /// ITEMS
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (_, i) {
                                      return buildItemCard(
                                        item: items[i],
                                        companyName: company["companyName"],
                                        subCustomerName:
                                            mapping["subCustomerName"],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            })
                            .toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          /// 🔹 SAVE BUTTON (LAST)
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15F28),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: saveCameronBoxData,
                child: Text(
                  "save".tr(),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showPrintOptions(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: const Color(0xFF010440), size: 24),
                    SizedBox(width: 6),
                    Text(
                      "print_all".tr(),
                      style: TextStyle(
                        color: const Color(0xFFF15F28),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.grid_view),
                title: const Text("6 Labels in One Page"),
                onTap: () {
                  Navigator.pop(context);
                  printAllCameronBoxes(); // 👈 EXISTING FUNCTION
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_portrait),
                title: const Text("Single Label"),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleLabelSizes(context); // 👈 NEW FUNCTION
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSingleLabelSizes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sizeTile(context, "4 × 6 inch", 4, 6),
              _sizeTile(context, "4 × 4 inch", 4, 4),
              _sizeTile(context, "4 × 2 inch", 4, 2),
            ],
          ),
        );
      },
    );
  }

  Widget _sizeTile(
    BuildContext context,
    String title,
    double width,
    double height,
  ) {
    return ListTile(
      leading: const Icon(Icons.print),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        printSingleLabelPerPage(width, height);
      },
    );
  }

  Future<void> printSingleLabelPerPage(
    double widthInch,
    double heightInch,
  ) async {
    final companies = await cameronFuture;
    if (companies == null || companies.isEmpty) return;

    final pdf = pw.Document();

    final logoBytes =
        (await rootBundle.load(
          'assets/images/shared image.jpg',
        )).buffer.asUint8List();
    final logo = pw.MemoryImage(logoBytes);

    final approvedBytes =
        (await rootBundle.load(
          'assets/images/approved.jpg',
        )).buffer.asUint8List();
    final approvedImage = pw.MemoryImage(approvedBytes);

    final bool isSmallLabel = heightInch <= 4;
    final bool isVerySmallLabel = heightInch <= 2;

    final double titleFont =
        isVerySmallLabel
            ? 4
            : isSmallLabel
            ? 12
            : 18;
    final double textFont =
        isVerySmallLabel
            ? 2
            : isSmallLabel
            ? 8
            : 12;
    final double qrSize =
        isVerySmallLabel
            ? 20
            : isSmallLabel
            ? 40
            : 70;
    final double logoSize =
        isVerySmallLabel
            ? 20
            : isSmallLabel
            ? 50
            : 60;
    final double qcWidth =
        isVerySmallLabel
            ? 20
            : isSmallLabel
            ? 50
            : 80;

    for (var company in companies) {
      for (var mapping in company["mapping"]) {
        for (var item in mapping["items"]) {
          final cameronBoxes = item["cameronBox"] as List;

          for (var box in cameronBoxes) {
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(
                  widthInch * PdfPageFormat.inch, // ✅ WIDTH
                  heightInch * PdfPageFormat.inch, // ✅ HEIGHT
                ),
                margin: const pw.EdgeInsets.all(12),
                build: (context) {
                  final companyCode = buildCompanyCode(company["companyName"]);
                  final codeText = "$companyCode${mapping["subCustomerId"]}";

                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                    ),
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        /// 🔷 BIG CENTER CODE
                        pw.Center(
                          child: pw.Text(
                            codeText,
                            style: pw.TextStyle(
                              fontSize: titleFont,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        pw.Divider(),

                        /// 🔹 DETAILS
                        _rows(
                          "Point",
                          mapping["subCustomerName"],
                          fontSize: textFont,
                        ),
                        _rows(
                          "Zone",
                          company["companyName"],
                          fontSize: textFont,
                        ),

                        if (!isVerySmallLabel)
                          _rows("Meal", widget.mealName, fontSize: textFont),

                        if (!isVerySmallLabel)
                          _rows("Date", widget.date, fontSize: textFont),

                        _rows("Item", item["itemName"], fontSize: textFont),
                        _rows(
                          "Qty",
                          box["receivedQty"].toString(),
                          fontSize: textFont,
                        ),

                        if (!isVerySmallLabel) pw.SizedBox(height: 12),

                        /// 🔶 QC + QR SAME LINE
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Image(
                              approvedImage,
                              width: qcWidth,
                              height: qcWidth * 0.6,
                            ),

                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data:
                                  "$companyCode${mapping["subCustomerId"]}"
                                  "|${mapping["subCustomerName"]}"
                                  "|${company["companyName"]}"
                                  "|${item["itemName"]}"
                                  "|${box["receivedQty"]}",
                              width: qrSize,
                              height: qrSize,
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 10),

                        /// 🔴 BIG DIVIDER
                        pw.Container(
                          height: isVerySmallLabel ? 0.8 : 1,
                          color: PdfColors.black,
                        ),

                        pw.SizedBox(height: 8),

                        /// 🔷 BOX COUNT + LOGO
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "BOX ${box["no"]} OF ${cameronBoxes.length}",
                              style: pw.TextStyle(
                                fontSize:
                                    isVerySmallLabel
                                        ? 6
                                        : isSmallLabel
                                        ? 10
                                        : 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Image(
                              logo,
                              width: isVerySmallLabel ? 15 : logoSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        }
      }
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _rows(
    String title,
    String value, {
    double fontSize = 12, // 👈 default font size
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              "$title :",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fontSize)),
          ),
        ],
      ),
    );
  }

  Future<void> printAllCameronBoxes() async {
    final companies = await cameronFuture;
    if (companies == null || companies.isEmpty) return;

    final pdf = pw.Document();

    /// ✅ LOAD UNICODE FONT
    final fontData = await rootBundle.load('assets/fonts/DMSans-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);

    /// ✅ LOAD IMAGES
    final logoBytes =
        (await rootBundle.load(
          'assets/images/shared image.jpg',
        )).buffer.asUint8List();
    final approvedBytes =
        (await rootBundle.load(
          'assets/images/approved.jpg',
        )).buffer.asUint8List();

    final logo = pw.MemoryImage(logoBytes);
    final approvedImage = pw.MemoryImage(approvedBytes);

    /// ✅ COLLECT ALL BOXES
    final List<Map<String, dynamic>> allBoxes = [];

    for (final company in companies) {
      final mappings = company["mapping"] as List? ?? [];
      for (final mapping in mappings) {
        final items = mapping["items"] as List? ?? [];
        for (final item in items) {
          final cameronBoxes = item["cameronBox"] as List? ?? [];
          for (final box in cameronBoxes) {
            final companyCode = buildCompanyCode(company["companyName"] ?? "");

            allBoxes.add({
              "companyName": company["companyName"] ?? "",
              "subCustomerName": mapping["subCustomerName"] ?? "",
              "mealName": widget.mealName,
              "date": widget.date,
              "itemName": item["itemName"] ?? "",
              "receivedQty": box["receivedQty"].toString(),
              "no": box["no"].toString(),
              "totalBoxes": cameronBoxes.length.toString(),
              "codes": "$companyCode${mapping["subCustomerId"]}",
              "code": "$companyCode (${box["no"]}/${cameronBoxes.length})",
            });
          }
        }
      }
    }

    /// ✅ MULTI PAGE WITH GRID (NO CRASH)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        maxPages: 200, // safety guard
        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              // 2 columns
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              // controls height
              children:
                  allBoxes.map((box) {
                    return _buildCameronBox(
                      box: box,
                      logo: logo,
                      approvedImage: approvedImage,
                      font: ttf,
                    );
                  }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildCameronBox({
    required Map<String, dynamic> box,
    required pw.ImageProvider logo,
    required pw.ImageProvider approvedImage,
    required pw.Font font,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          /// CODE
          pw.Center(
            child: pw.Text(
              box["codes"],
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.Divider(),

          _row("Point", box["subCustomerName"], font),
          _row("Zone", box["companyName"], font),
          _row("Meal", box["mealName"], font),
          _row("Date", box["date"], font),
          _row("Item", box["itemName"], font),
          _row("Qty", box["receivedQty"], font),

          pw.SizedBox(height: 4),

          /// QC + QR
          pw.Stack(
            children: [
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(approvedImage, width: 60),
              ),
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Transform.translate(
                  offset: const PdfPoint(0, -8),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    width: 32,
                    height: 45,
                    data:
                        "${box["code"]}|${box["subCustomerName"]}|${box["companyName"]}|${box["mealName"]}|${box["date"]}|${box["itemName"]}|${box["receivedQty"]}",
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          pw.Container(height: 0.5, color: PdfColors.black),

          pw.SizedBox(height: 4),

          /// BOX COUNT + LOGO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "BOX ${box["no"]} OF ${box["totalBoxes"]}",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Image(logo, width: 35),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _row(String title, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 48,
            child: pw.Text(
              "$title:",
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Future<void> saveCameronBoxData() async {
    final companies = await cameronFuture;
    final url =
        "${AppConfig.localBaseUrl}/api/saveCameronBoxMobile/${widget.date}/${widget.mealId}/Gcc";

    /// Build payload from existing data
    final payload =
        companies!.map((company) {
          return {
            "companyId": company["companyId"],
            "companyName": company["companyName"],
            "mapping":
                (company["mapping"] as List).map((mapping) {
                  return {
                    "subCustomerId": mapping["subCustomerId"],
                    "subCustomerName": mapping["subCustomerName"],
                    "vehicleId": mapping["vehicleId"],
                    "vehicleName": mapping["vehicleName"],
                    "paxCount": mapping["paxCount"],
                    "items":
                        (mapping["items"] as List).map((item) {
                          return {
                            "kitchenId": item["kitchenId"],
                            "kitchenName": item["kitchenName"],
                            "itemId": item["itemId"],
                            "itemName": item["itemName"],
                            "mealCount": item["mealCount"],
                            "quantity": item["quantity"],
                            "weight": item["weight"],
                            "cameronBox":
                                (item["cameronBox"] as List).map((box) {
                                  return {
                                    "no": box["no"],
                                    "receivedQty": box["receivedQty"],
                                    "box": box["box"],
                                  };
                                }).toList(),
                          };
                        }).toList(),
                  };
                }).toList(),
          };
        }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: ${response.body}")));
    }
  }

  String buildCompanyCode(String companyName) {
    // Remove _ and spaces
    final cleaned = companyName.replaceAll(RegExp(r'[_\s]'), '');

    // Take first 7 characters safely (VII + ANNA)
    final prefix = cleaned.length >= 7 ? cleaned.substring(0, 7) : cleaned;

    return "${prefix.toUpperCase()}-WAR";
  }

  // ================= ITEM CARD =================
  Widget buildItemCard({
    required dynamic item,
    required String companyName,
    required String subCustomerName,
  }) {
    final cameronBoxes = item["cameronBox"] as List;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ITEM HEADER
          Row(
            children: [
              Expanded(
                child: Text(
                  item["itemName"],
                  style: const TextStyle(
                    color: Color(0xFFF15F28),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Qty: ${item["quantity"]}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// CAMERON HEADER WITH ADD BUTTON
          Row(
            children: [
              Text(
                "cameron".tr(),
                style: TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    // Add a new Cameron box
                    cameronBoxes.add({
                      "no": cameronBoxes.length + 1,
                      "receivedQty": 0.0,
                    });
                  });
                },
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFF15F28),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// CAMERON BOXES
          ...cameronBoxes.map((box) {
            final controller = TextEditingController(
              text: box["receivedQty"].toString(),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text("Cameron ${box["no"]}"),
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Color(0xFFF15F28)),
                        labelStyle: const TextStyle(color: Color(0xFFF15F28)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: "weight".tr(),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            box["receivedQty"] = double.tryParse(value) ?? 0.0;
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.monitor_weight,
                          color: Color(0xFF010440),
                        ),
                        onPressed: () {
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            cameronBoxes.remove(box);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
