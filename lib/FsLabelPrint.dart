import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'config_loader.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FsLabelMealSelectionPage extends StatefulWidget {
  final String companyId;

  const FsLabelMealSelectionPage({super.key, required this.companyId});

  @override
  State<FsLabelMealSelectionPage> createState() =>
      _FsLabelMealSelectionPageState();
}

class _FsLabelMealSelectionPageState extends State<FsLabelMealSelectionPage> {
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

  const CameronPage({
    super.key,
    required this.companyId,
    required this.mealId,
    required this.date,
    required this.mealName,
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
        "${AppConfig.localBaseUrl}/api/mealReadyTrackerCompanyMobile/${widget.date}/${widget.mealId}/${widget.companyId}/Fs";

    final response = await http.get(Uri.parse(url));
    debugPrint("response body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["data"];
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

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No data found"));
                }

                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text("No data available"));
                }

                final companies = (snapshot.data![0] as List?) ?? [];
                vehicles = (snapshot.data![1] as List?) ?? [];
                if (companies.isEmpty) {
                  return const Center(
                    child: Text(
                      "No data found",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
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

                        ...mappings.map((mapping) {
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
                                    filteredVehicles.map<DropdownMenuItem<int>>(
                                      (v) {
                                        return DropdownMenuItem<int>(
                                          value: v["id"],
                                          child: Text(v["name"]),
                                        );
                                      },
                                    ).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    mapping["vehicleId"] = value;
                                    final selected = filteredVehicles
                                        .firstWhere((v) => v["id"] == value);
                                    mapping["vehicleName"] = selected["name"];
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
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  return buildItemCard(
                                    item: items[i],
                                    companyName: company["companyName"],
                                    subCustomerName: mapping["subCustomerName"],
                                    subCustomerId: mapping["subCustomerId"],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }).toList(),
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
        ],
      ),
    );
  }

  Future<void> saveCameronBoxData() async {
    final companies = await cameronFuture;

    final url =
        "${AppConfig.localBaseUrl}/api/saveCameronBoxMobile/${widget.date}/${widget.mealId}/Fs";

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
    final prefix = cleaned.length >= 7
        ? cleaned.substring(0, 7)
        : cleaned;

    return "${prefix.toUpperCase()}-WAR";
  }

  // ================= ITEM CARD =================
  Widget buildItemCard({
    required dynamic item,
    required String companyName,
    required String subCustomerName,
    required int subCustomerId,
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
            final companyCode = buildCompanyCode(companyName);

            final code =
                "$companyCode$subCustomerId (${box["no"]}/${cameronBoxes.length})";

            final codes = "$companyCode$subCustomerId";

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

                  /// PRINT BUTTON
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        openPrintPreview(
                          code: code,
                          codes: codes,
                          point: subCustomerName,
                          // ✅ SUB CUSTOMER
                          zone: companyName,
                          meal: widget.mealName,
                          date: widget.date,
                          item: item["itemName"],
                          no: box["no"].toString(),
                          qty: box["receivedQty"].toString(),
                          totalBoxes: cameronBoxes.length,
                        );
                      },
                      icon: const Icon(
                        Icons.print,
                        color: Color(0xFFF15F28),
                        size: 18,
                      ),
                      label: Text(
                        "print".tr(),
                        style: const TextStyle(color: Color(0xFFF15F28)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF15F28)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> openPrintPreview({
    required String code,
    required String codes,
    required String point,
    required String zone,
    required String meal,
    required String date,
    required String item,
    required String no,
    required String qty,
    required int totalBoxes,
  }) async {
    final pdf = pw.Document();

    // Load logo
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          4 * PdfPageFormat.inch, // width
          6 * PdfPageFormat.inch, // height
        ),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                /// 🔷 CODE IN CENTER
                pw.Center(
                  child: pw.Text(
                    codes,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _row("Point", point),
                _row("Zone", zone),
                _row("Meal", meal),
                _row("Date", date),
                _row("Item", item),
                _row("Qty", qty),
                pw.SizedBox(height: 12),

                /// 🔶 QC CHECKED (LEFT) + QR CODE (RIGHT)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // LEFT – Approved Image
                    pw.Row(
                      children: [
                        pw.Text(
                          "",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Image(approvedImage, width: 80, height: 55),
                      ],
                    ),

                    // RIGHT – QR CODE
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: "$code|$point|$zone|$meal|$date|$item|$qty",
                      width: 70,
                      height: 70,
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                /// 🔴 DIVIDER
                pw.Container(
                  height: 2,
                  width: double.infinity,
                  color: PdfColors.black,
                ),

                pw.SizedBox(height: 8),

                /// 🔷 BOX COUNT (LEFT) + LOGO (RIGHT)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "BOX $no OF $totalBoxes",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.Image(logo, width: 60),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    /// 🔥 THIS OPENS PDF PREVIEW (like your screenshot)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _row(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              "$title :",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
