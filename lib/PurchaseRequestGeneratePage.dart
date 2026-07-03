import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodswing_flutter/config_loader.dart';
import 'package:http/http.dart' as http;
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class PurchaseRequestGeneratePage extends StatefulWidget {
  final String companyId;

  const PurchaseRequestGeneratePage({super.key, required this.companyId});

  @override
  State<PurchaseRequestGeneratePage> createState() =>
      _PurchaseRequestGeneratePageState();
}

class _PurchaseRequestGeneratePageState
    extends State<PurchaseRequestGeneratePage> {
  List<Map<String, dynamic>> kitchens = [];
  List<Map<String, dynamic>> meals = [];

  List<Map<String, dynamic>> selectedKitchens = [];
  List<Map<String, dynamic>> selectedMeals = [];

  String source = "Production Plan";
  String kitchen = "Central Kitchen";
  String meal = "Breakfast";
  String category = "Non Perishable";
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    fromDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    toDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    loadMeals();
    loadKitchens();
  }

  Future<void> loadKitchens() async {
    final response = await http.get(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/kitchenByCompany/${widget.companyId}",
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      setState(() {
        kitchens = List<Map<String, dynamic>>.from(jsonData["data"]);
      });
    }
  }

  Future<void> loadMeals() async {
    final response = await http.get(
      Uri.parse("${AppConfig.localBaseUrl}/api/mealAllGetMobile/list"),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      setState(() {
        meals = List<Map<String, dynamic>>.from(jsonData["data"]);
      });
    }
  }

  Future<void> generatePurchaseRequest() async {
    if (selectedMeals.isEmpty || selectedKitchens.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Kitchen and Meal")));

      return;
    }

    final mealIds = selectedMeals.map((e) => e["id"].toString()).join(",");

    final kitchenIds = selectedKitchens
        .map((e) => e["id"].toString())
        .join(",");

    final url =
        "${AppConfig.apiBaseUrl}/api/savePurchaseRequest/"
        "${fromDateController.text}/"
        "${toDateController.text}/"
        "$mealIds/"
        "$kitchenIds";

    print(url);

    final response = await http.post(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(json["status"]["message"])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate Purchase Request")),
      );
    }
  }

  Future<void> _pickDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;

        final date = "${picked.day}-${picked.month}-${picked.year}";

        if (isFromDate) {
          fromDateController.text = date;
        } else {
          toDateController.text = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: const Text("Generate PR"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Purchase Request Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              "Fill the details to generate the purchase request",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 25),

            /// SOURCE
            DropdownButtonFormField<String>(
              value: source,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Source",
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Production Plan",
                  child: Text("Production Plan"),
                ),
              ],
              onChanged: (v) {
                setState(() => source = v!);
              },
            ),

            const SizedBox(height: 18),

            /// FROM & TO
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: fromDateController,
                    readOnly: true,
                    onTap: () => _pickDate(true),
                    decoration: InputDecoration(
                      labelText: "From Date",
                      prefixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: TextFormField(
                    controller: toDateController,
                    readOnly: true,
                    onTap: () => _pickDate(false),
                    decoration: InputDecoration(
                      labelText: "To Date",
                      prefixIcon: const Icon(Icons.event),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// KITCHEN & MEAL
            Row(
              children: [
                Expanded(
                  child: MultiSelectDialogField<Map<String, dynamic>>(
                    items: kitchens
                        .map(
                          (e) => MultiSelectItem<Map<String, dynamic>>(
                            e,
                            e["name"],
                          ),
                        )
                        .toList(),
                    title: const Text("Kitchen"),
                    buttonText: Text(
                      selectedKitchens.isEmpty
                          ? "Kitchen"
                          : selectedKitchens.length == 1
                          ? selectedKitchens.first["name"]
                          : "${selectedKitchens.first["name"]} +${selectedKitchens.length - 1}",
                    ),
                    searchable: true,
                    initialValue: selectedKitchens,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                    ),
                    buttonIcon: const Icon(Icons.restaurant),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) {
                      setState(() {
                        selectedKitchens = values;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 15),
                Expanded(
                  child: MultiSelectDialogField<Map<String, dynamic>>(
                    items: meals
                        .map(
                          (e) => MultiSelectItem<Map<String, dynamic>>(
                            e,
                            e["name"],
                          ),
                        )
                        .toList(),
                    title: const Text("Meal"),

                    buttonText: Text(
                      selectedMeals.isEmpty
                          ? "Meal"
                          : selectedMeals.length == 1
                          ? selectedMeals.first["name"]
                          : "${selectedMeals.first["name"]} +${selectedMeals.length - 1}",
                    ),
                    searchable: true,
                    initialValue: selectedMeals,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                    ),
                    buttonIcon: const Icon(Icons.fastfood),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) {
                      setState(() {
                        selectedMeals = values;
                      });
                    },
                  ),
                ),
              ],
            ),

            // const SizedBox(height: 18),
            //
            // /// CATEGORY
            // DropdownButtonFormField<String>(
            //   value: category,
            //   isExpanded: true,
            //   decoration: InputDecoration(
            //     labelText: "Category",
            //     prefixIcon: const Icon(Icons.category_outlined),
            //     filled: true,
            //     fillColor: Colors.white,
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(18),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(18),
            //       borderSide: BorderSide(color: Colors.grey.shade300),
            //     ),
            //   ),
            //   items: const [
            //     DropdownMenuItem(
            //       value: "Non Perishable",
            //       child: Text("Non Perishable"),
            //     ),
            //     DropdownMenuItem(
            //       value: "Perishable",
            //       child: Text("Perishable"),
            //     ),
            //   ],
            //   onChanged: (v) {
            //     setState(() => category = v!);
            //   },
            // ),

            // const SizedBox(height: 20),
            //
            // Card(
            //   child: ListTile(
            //     leading: const Icon(Icons.analytics, color: Colors.orange),
            //     title: const Text("Preview"),
            //     subtitle: const Text(
            //       "Items : 18\nEstimated Amount : ₹1,25,500",
            //     ),
            //   ),
            // ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF15F28),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: generatePurchaseRequest,
                icon: const Icon(Icons.auto_mode),
                label: const Text(
                  "Generate Purchase Request",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
