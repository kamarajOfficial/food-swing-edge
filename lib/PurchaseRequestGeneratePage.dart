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
  List<Map<String,dynamic>> ingredientMaster = [];

  DateTime selectedDate = DateTime.now();

  String formatApiDate(DateTime d) {
    return "${d.year}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();

    fromDateController.text = formatApiDate(selectedDate);
    toDateController.text = formatApiDate(selectedDate);

    loadMeals();
    loadKitchens();
    loadIngredientMaster();
  }

  Future<void> loadIngredientMaster() async {

    final response = await http.get(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/ingredientAllGet/list",
      ),
    );

    if(response.statusCode==200){

      final json=jsonDecode(response.body);

      setState((){

        ingredientMaster=
        List<Map<String,dynamic>>.from(json["data"]);

      });

    }

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

  Future<void> previewPurchaseRequest() async {
    if (selectedMeals.isEmpty || selectedKitchens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Kitchen and Meal")),
      );
      return;
    }

    final mealIds =
    selectedMeals.map((e) => e["id"].toString()).join(",");

    final kitchenIds =
    selectedKitchens.map((e) => e["id"].toString()).join(",");

    final response = await http.get(
      Uri.parse(
        "${AppConfig.apiBaseUrl}"
            "/api/projection/preparation/"
            "${fromDateController.text}/"
            "${toDateController.text}/"
            "$mealIds/"
            "$kitchenIds",
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseRequestPreviewPage(
            ingredients: List<Map<String, dynamic>>.from(json["data"]),
            fromDate: fromDateController.text,
            toDate: toDateController.text,
            mealIds: mealIds,
            kitchenIds: kitchenIds,
          ),
        ),
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

        String formatApiDate(DateTime d) {
          return "${d.year}-"
              "${d.month.toString().padLeft(2, '0')}-"
              "${d.day.toString().padLeft(2, '0')}";
        }
        if (isFromDate) {
          fromDateController.text = formatApiDate(picked);
        } else {
          toDateController.text = formatApiDate(picked);
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
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF15F28),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: previewPurchaseRequest,
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

class PurchaseRequestPreviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final String fromDate;
  final String toDate;
  final String mealIds;
  final String kitchenIds;

  const PurchaseRequestPreviewPage({
    Key? key,
    required this.ingredients,
    required this.fromDate,
    required this.toDate,
    required this.mealIds,
    required this.kitchenIds,
  }) : super(key: key);

  @override
  State<PurchaseRequestPreviewPage> createState() =>
      _PurchaseRequestPreviewPageState();
}

class _PurchaseRequestPreviewPageState
    extends State<PurchaseRequestPreviewPage> {
  List<Map<String, dynamic>> ingredients = [];
  List<Map<String, dynamic>> ingredientMaster = [];

  @override
  void initState() {
    super.initState();
    ingredients = List<Map<String, dynamic>>.from(widget.ingredients);
    loadIngredientMaster();
  }

  Future<void> loadIngredientMaster() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/ingredientAllGet/list"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        ingredientMaster =
        List<Map<String, dynamic>>.from(json["data"]);
      });
    }
  }

  double get totalQty {
    return ingredients.fold(
      0,
          (sum, item) =>
      sum + ((item["quantity"] ?? 0) as num).toDouble(),
    );
  }

  double get totalAmount {
    return ingredients.fold(
      0,
          (sum, item) =>
      sum +
          (((item["quantity"] ?? 0) as num).toDouble() *
              ((item["unitRate"] ?? 0) as num).toDouble()),
    );
  }

  Future<void> savePurchaseRequest() async {
    final body = {
      "fromDate": widget.fromDate,
      "toDate": widget.toDate,
      "mealIds": widget.mealIds.split(",").map(int.parse).toList(),
      "kitchenIds": widget.kitchenIds.split(",").map(int.parse).toList(),
      "ingredients": ingredients
          .map((e) => {
        "ingredientId": e["ingredientId"],
        "quantity": e["quantity"]
      })
          .toList()
    };

    print(jsonEncode(body));

    /// Replace with your save API
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/savePurchaseRequest"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json["status"]["message"])),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save PR")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),
      body: ingredientMaster.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  summary("Items", ingredients.length.toString()),
                  summary("Qty", totalQty.toStringAsFixed(2)),
                  summary("Amount",
                      "₹${totalAmount.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 6,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 40,
                headingRowHeight: 36,
                headingRowColor:
                WidgetStateProperty.all(const Color(0xFFF15F28)),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: const TextStyle(fontSize: 11),
                columns: const [
                  DataColumn(label: Text("Ingredient")),
                  DataColumn(label: Text("Qty")),
                  DataColumn(label: Text("Rate")),
                  DataColumn(label: Text("Cost")),
                  DataColumn(label: Text("")),
                ],
                rows: ingredients.map((item) {

                  Map<String, dynamic>? selectedIngredient;

                  try {
                    selectedIngredient = ingredientMaster.firstWhere(
                          (e) => e["id"].toString() == item["ingredientId"].toString(),
                    );
                  } catch (_) {
                    selectedIngredient = null;
                  }

                  return DataRow(
                    cells: [
                      /// Ingredient
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              isExpanded: true,
                              iconSize: 18,
                              value: selectedIngredient,
                              hint: Text(
                                "${item["ingredientName"]}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              items: ingredientMaster.map((ingredient) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: ingredient,
                                  child: SizedBox(
                                    width: 170,
                                    child: Text(
                                      ingredient["name"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (selected) {
                                if (selected == null) return;

                                setState(() {
                                  item["ingredientId"] = selected["id"];

                                  final name =
                                      selected["name"]?.toString() ?? "";

                                  final parts = name.split(" - ");

                                  item["ingredientName"] = parts.first;
                                  item["erpId"] =
                                  parts.length > 1 ? parts.last : "";

                                  item["unitRate"] =
                                      (selected["cost"] as num?)?.toDouble() ??
                                          0;

                                  item["name"] = selected["uomName"];
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      /// Qty
                      DataCell(
                        SizedBox(
                          width: 55,
                          child: TextFormField(
                            initialValue: item["quantity"].toString(),
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                            keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                item["quantity"] =
                                    double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                      ),

                      /// Rate
                      DataCell(
                        SizedBox(
                          width: 55,
                          child: Text(
                            "₹${(item["unitRate"] as num).toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),

                      /// Cost
                      DataCell(
                        SizedBox(
                          width: 65,
                          child: Text(
                            "₹${(((item["quantity"] ?? 0) as num).toDouble() * ((item["unitRate"] ?? 0) as num).toDouble()).toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),

                      /// Delete
                      DataCell(
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          splashRadius: 18,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              ingredients.remove(item);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15F28),
                ),
                onPressed: savePurchaseRequest,
                icon: const Icon(Icons.save),
                label: const Text(
                  "Save Purchase Request",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget summary(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 5),
        Text(title),
      ],
    );
  }
}
