import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'config_loader.dart';
import 'package:http/http.dart' as http;

class WastageMealSelectionPage extends StatefulWidget {
  final String companyId;

  const WastageMealSelectionPage({super.key, required this.companyId});

  @override
  State<WastageMealSelectionPage> createState() =>
      _WastageMealSelectionPageState();
}

class _WastageMealSelectionPageState extends State<WastageMealSelectionPage> {
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
        title: Text("wastage_management").tr(),
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
                                      (_) => WastagePage(
                                        companyId: widget.companyId,
                                        mealId: selectedMeal["id"],
                                        date: formattedDate,
                                        mealName: selectedMeal["name"],
                                      ),
                                ),
                              );
                            },
                            child: const Text(
                              "Next",
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

class WastagePage extends StatefulWidget {
  final String companyId;
  final int mealId;
  final String date;
  final String mealName;

  const WastagePage({
    super.key,
    required this.companyId,
    required this.mealId,
    required this.date,
    required this.mealName,
  });

  @override
  State<WastagePage> createState() => _WastagePageState();
}

class _WastagePageState extends State<WastagePage> {
  bool loading = true;
  Map<String, dynamic>? wastageData;

  final TextEditingController notesController = TextEditingController();

  void setNotesFromResponse(Map<String, dynamic> response) {
    notesController.text = response["notes"] ?? "";
  }

  @override
  void initState() {
    super.initState();
    fetchWastageData();
  }

  Future<void> fetchWastageData() async {
    try {
      final url =
          "${AppConfig.localBaseUrl}/api/companyWiseWastage/${widget.date}/${widget.mealId}/${widget.companyId}";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["data"];

        setState(() {
          wastageData = data;
          loading = false;
        });

        // ✅ SET NOTES INTO TEXTFIELD
        setNotesFromResponse(data);
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (wastageData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("No data found")),
      );
    }

    final items = wastageData!["items"] as List<dynamic>;

    final plateController = TextEditingController(
      text: wastageData!["saleCount"].toString(),
    );
    final binWasteController = TextEditingController(
      text: wastageData!["binWaste"].toString(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "enter_wastage".tr(),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Text(
              "${widget.mealName} • ${widget.date} • ${wastageData!["companyName"]}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.05,
            child: Center(child: Image.asset("assets/images/watermark.jpg")),
          ),

          // ⭐ MAIN SCROLL VIEW WITH STICKY HEADER ⭐
          CustomScrollView(
            slivers: [
              // TOP BOX
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${'order_count'.tr()}: ${wastageData!["mealCount"]}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: textFieldBox(
                              label: "plate".tr(),
                              controller: plateController,
                              icon: Icons.restaurant_menu,
                              onChanged:
                                  (v) =>
                                      wastageData!["saleCount"] =
                                          int.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: textFieldBox(
                              label: "bin_waste".tr(),
                              controller: binWasteController,
                              icon: Icons.delete_outline,
                              onChanged:
                                  (v) =>
                                      wastageData!["binWaste"] =
                                          double.tryParse(v) ?? 0.0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ⭐ FREEZE HEADER HERE ⭐
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyHeaderDelegate(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "quantity_produced".tr(),
                            textAlign: TextAlign.center,
                            maxLines: 9,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "bain_marie_waste".tr(),
                            textAlign: TextAlign.center,
                            maxLines: 9,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "shortage".tr(),
                            textAlign: TextAlign.center,
                            maxLines: 9,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ⭐ LIST OF ITEMS ⭐
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  final controller = TextEditingController(
                    text:
                        (item["quantityWasted"] == null ||
                                item["quantityWasted"] == 0)
                            ? ""
                            : item["quantityWasted"].toString(),
                  );

                  final shortageController = TextEditingController(
                    text:
                        (item["shortage"] == null || item["shortage"] == 0)
                            ? ""
                            : item["shortage"].toString(),
                  );

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["itemName"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              /// Produced
                              Expanded(
                                child: Text(
                                  "${item["quantityProduced"]} ${item["name"]}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              /// Dispatched
                              // Expanded(
                              //   child: Text(
                              //     "${item["quantityDispatched"]}",
                              //     style: const TextStyle(
                              //       fontSize: 15,
                              //       fontWeight: FontWeight.w500,
                              //     ),
                              //   ),
                              // ),

                              /// Bain Marie Waste
                              Expanded(
                                child: _numberField(
                                  controller: controller,
                                  unit: item["name"],
                                  onChanged: (value) {
                                    item["quantityWasted"] =
                                        value.trim().isEmpty
                                            ? null
                                            : double.tryParse(value) ?? 0.0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              /// Shortage
                              Expanded(
                                child: _numberField(
                                  controller: shortageController,
                                  unit: item["name"],
                                  onChanged: (value) {
                                    item["shortage"] =
                                        value.trim().isEmpty
                                            ? null
                                            : double.tryParse(value) ?? 0.0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: items.length),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "notes".tr(), // or "Notes"
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "enter_notes".tr(),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            wastageData!["notes"] = value.trim();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: submitWastage,
                    child: Text(
                      "submit".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 60,
            right: 23,
            child: Transform.scale(
              scale: 5.5,
              child: Image.asset(
                'assets/images/sauceit.png',
                width: 25,
                height: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void submitWastage() async {
    if (wastageData == null) return;

    // ================= VALIDATION =================
    if ((wastageData!["saleCount"] == null || wastageData!["saleCount"] == 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plate count is mandatory")));
      return;
    }

    if ((wastageData!["binWaste"] == null || wastageData!["binWaste"] == 0.0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bin waste is mandatory")));
      return;
    }

    // ================= PAYLOAD =================
    final payload = {
      "companyId": int.tryParse(widget.companyId) ?? 0,
      "companyName": wastageData!["companyName"] ?? "",
      "mealId": widget.mealId,
      "mealName": widget.mealName,
      "orderDate": widget.date,
      "mealCount": wastageData!["mealCount"] ?? 0,
      "saleCount": wastageData!["saleCount"],
      "binWaste": wastageData!["binWaste"],
      "notes": wastageData!["notes"],
      "items":
          (wastageData!["items"] as List<dynamic>).map((item) {
            return {
              "itemId": item["itemId"],
              "itemName": item["itemName"],
              "uomId": item["uomId"],
              "name": item["name"],
              "grammage": item["grammage"],
              "quantityProduced": item["quantityProduced"],
              "quantityDispatched": item["quantityDispatched"],
              "quantityWasted": item["quantityWasted"],
              "shortage": item["shortage"],
            };
          }).toList(),
    };

    // ================= API CALL =================
    try {
      final url = "${AppConfig.localBaseUrl}/api/saveCompanyWiseWastage";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wastage submitted successfully!")),
        );
        Navigator.pop(context); // go back after successful submission
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to submit wastage. Status code: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting wastage: $e")));
    }
  }
}

// ---------------------- Sticky Header Delegate ------------------------

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) => false;
}

// ---------------------- REUSABLE TEXT FIELD BOX ------------------------

Widget textFieldBox({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Text(" *", style: TextStyle(color: Colors.grey)),
        ],
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon, color: Color(0xFFF15F28)),
        ),
        onChanged: onChanged,
      ),
    ],
  );
}
