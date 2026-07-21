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
  List<Map<String, dynamic>> ingredientMaster = [];

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

  Future<void> previewPurchaseRequest() async {
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
      print(jsonEncode(json["data"]));

      print("Response: ${response}");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseRequestPreviewPage(
            ingredients: List<Map<String, dynamic>>.from(json["data"]),
            fromDate: fromDateController.text,
            toDate: toDateController.text,
            mealIds: mealIds,
            kitchenIds: kitchenIds,
            companyId: widget.companyId,
            source: source,
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

  void openMealDialog() async {
    List<Map<String, dynamic>> tempSelected = List.from(selectedMeals);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Meal"),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    /// Select All & Clear
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              tempSelected = List.from(meals);
                            });
                          },
                          child: const Text("Select All"),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),

                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];

                          final selected = tempSelected.any(
                                (e) => e["id"] == meal["id"],
                          );

                          return CheckboxListTile(
                            value: selected,
                            title: Text(meal["name"]),
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value!) {
                                  tempSelected.add(meal);
                                } else {
                                  tempSelected.removeWhere(
                                        (e) => e["id"] == meal["id"],
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    setState(() {
                      selectedMeals = List.from(tempSelected);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openKitchenDialog() async {
    List<Map<String, dynamic>> tempSelected = List.from(selectedKitchens);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Kitchen"),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [

                    /// Select All & Clear
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              tempSelected = List.from(kitchens);
                            });
                          },
                          child: const Text("Select All"),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),

                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount: kitchens.length,
                        itemBuilder: (context, index) {
                          final kitchen = kitchens[index];

                          final selected = tempSelected.any(
                                (e) => e["id"] == kitchen["id"],
                          );

                          return CheckboxListTile(
                            value: selected,
                            title: Text(kitchen["name"]),
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value!) {
                                  tempSelected.add(kitchen);
                                } else {
                                  tempSelected.removeWhere(
                                        (e) => e["id"] == kitchen["id"],
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    setState(() {
                      selectedKitchens = List.from(tempSelected);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: const Text("Generate PR"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Purchase Request Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "Fill the details to generate the purchase request",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 22),

            /// Source
            const Text(
              "Source",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),

            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: source,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Production Plan",
                  child: Text("Production Plan"),
                ),
                DropdownMenuItem(
                  value: "Manual Requisition",
                  child: Text("Manual Requisition"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  source = value!;
                });
              },
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "From Date",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextFormField(
                        controller: fromDateController,
                        readOnly: true,
                        onTap: () => _pickDate(true),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 22,
                              color: Colors.black,
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minHeight: 45,
                            minWidth: 45,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "To Date",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextFormField(
                        controller: toDateController,
                        readOnly: true,
                        onTap: () => _pickDate(false),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 22,
                              color: Colors.black,
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minHeight: 45,
                            minWidth: 45,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// Kitchen
            const Text(
              "Kitchen",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),

            const SizedBox(height: 6),

            InkWell(
              onTap: openKitchenDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedKitchens.isEmpty
                            ? "Select Kitchen"
                            : selectedKitchens.length == 1
                            ? selectedKitchens.first["name"]
                            : "${selectedKitchens.first["name"]} +${selectedKitchens.length - 1}",
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// Meal
            const Text(
              "Meal",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),

            const SizedBox(height: 6),

            InkWell(
              onTap: openMealDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood_outlined),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        selectedMeals.isEmpty
                            ? "Select Meal"
                            : selectedMeals.length == 1
                            ? selectedMeals.first["name"]
                            : "${selectedMeals.first["name"]} +${selectedMeals.length - 1}",
                      ),
                    ),

                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xff2457F5), Color(0xff1B46C5)],
                  ),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF15F28),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: previewPurchaseRequest,
                  icon: const Icon(Icons.autorenew, color: Colors.white),
                  label: const Text(
                    "Generate Purchase Request",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
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
  final String companyId;
  final String source;

  const PurchaseRequestPreviewPage({
    Key? key,
    required this.ingredients,
    required this.fromDate,
    required this.toDate,
    required this.mealIds,
    required this.kitchenIds,
    required this.companyId,
    required this.source,
  }) : super(key: key);

  @override
  State<PurchaseRequestPreviewPage> createState() =>
      _PurchaseRequestPreviewPageState();
}

class _PurchaseRequestPreviewPageState
    extends State<PurchaseRequestPreviewPage> {
  List<Map<String, dynamic>> ingredients = [];
  List<Map<String, dynamic>> ingredientMaster = [];
  late Map<String, Map<String, dynamic>> ingredientMap;
  late List<DropdownMenuItem<Map<String, dynamic>>> ingredientItems;

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
        ingredientMaster = List<Map<String, dynamic>>.from(json["data"]);

        ingredientMap = {for (var e in ingredientMaster) e["id"].toString(): e};

        ingredientItems = ingredientMaster.map((ingredient) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: ingredient,
            child: Text(
              ingredient["name"],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      });
    }
  }

  double get totalQty {
    return ingredients.fold(
      0,
      (sum, item) => sum + ((item["quantity"] ?? 0) as num).toDouble(),
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
      "kitchenId": int.parse(widget.kitchenIds),

      "mealIds": widget.mealIds.split(",").map((e) => int.parse(e)).toList(),

      "companyIds": [int.parse(widget.companyId)],

      "fromDate": widget.fromDate,
      "toDate": widget.toDate,
      "requiredByDate": widget.toDate,
      "priority": "High",
      "requestType": "Automation",
      "source": widget.source,
      "remarks": "",
      "actionBy": "Mobile PR",

      "ingredients": ingredients.map((e) {
        return {
          "ingredientId": e["ingredientId"],
          "ingredientName": e["ingredientName"],
          "ingredientCode": e["ingredientCode"],
          "uomId": e["uomId"],
          "uomName": e["uomName"],
          "ingredientTypeId": e["ingredientTypeId"],
          "ingredientTypeName": e["ingredientTypeName"],
          "perishableType": e["perishableType"],
          // "requiredQty": e["qty"],
          "availableStock": e["availableStock"],
          "reservedStock": e["reservedStock"],
          "pendingPoQty": e["pendingPoQty"],
          "requiredQty": e["quantity"],
          "estimatedUnitPrice": e["unitRate"],
          "estimatedAmount":
              ((e["quantity"] ?? 0) as num).toDouble() *
              ((e["unitRate"] ?? 0) as num).toDouble(),
          "netRequiredQty": e["netRequiredQty"],
          // "estimatedUnitPrice": e["estimatedUnitPrice"],
          // "estimatedAmount":
          //     ((e["qty"] ?? 0) as num).toDouble() *
          //     ((e["estimatedUnitPrice"] ?? 0) as num).toDouble(),
          "remarks": "",
          "sourceType": e["sourceType"],
          "sourceDate": e["sourceDate"],
          "orderDate": e["orderDate"],
          "originalOrderDates": e["originalOrderDates"],
          "mealId": e["mealId"],
          "mealName": e["mealName"],
          "productionPlanItems": e["productionPlanItems"],
        };
      }).toList(),
    };

    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/createDraft"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(json["status"]["message"])));

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryItem(
                            title: "Items",
                            value: ingredients.length.toString(),
                            alignment: CrossAxisAlignment.start,
                          ),
                        ),
                        Expanded(
                          child: _summaryItem(
                            title: "Qty",
                            value: totalQty.toStringAsFixed(2),
                            alignment: CrossAxisAlignment.center,
                          ),
                        ),
                        Expanded(
                          child: _summaryItem(
                            title: "Amount",
                            value: "₹${totalAmount.toStringAsFixed(2)}",
                            alignment: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white24,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                "Ingredient",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Qty",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Rate",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Cost",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: ingredients.length,
                          itemExtent: 72,
                          cacheExtent: 300,
                          itemBuilder: (context, index) {
                            return ingredientRow(index);
                          },
                        ),
                      ),
                    ],
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
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Save Purchase Request",
                        //   style: TextStyle(fontSize: 16)
                        // ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget ingredientRow(int index) {
    final item = ingredients[index];

    Map<String, dynamic>? selectedIngredient;

    try {
      selectedIngredient = ingredientMap[item["ingredientId"].toString()];
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _selectIngredient(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item["ingredientName"] ?? "Select Ingredient",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final controller = TextEditingController(
                  text: item["quantity"].toString(),
                );

                final value = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Enter Quantity"),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, controller.text);
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );

                if (value != null) {
                  setState(() {
                    item["quantity"] = double.tryParse(value) ?? 0;
                  });
                }
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item["quantity"].toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text("₹${item["unitRate"]}", textAlign: TextAlign.center),
          ),

          Expanded(
            flex: 2,
            child: Text(
              "₹${((item["quantity"] ?? 0) * (item["unitRate"] ?? 0)).toStringAsFixed(0)}",
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  ingredients.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required CrossAxisAlignment alignment,
  }) {
    TextAlign textAlign;

    switch (alignment) {
      case CrossAxisAlignment.start:
        textAlign = TextAlign.left;
        break;
      case CrossAxisAlignment.center:
        textAlign = TextAlign.center;
        break;
      case CrossAxisAlignment.end:
        textAlign = TextAlign.right;
        break;
      default:
        textAlign = TextAlign.left;
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF010440),
          ),
        ),
      ],
    );
  }

  void _selectIngredient(int rowIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: Column(
            children: [
              const SizedBox(height: 12),

              const Text(
                "Select Ingredient",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Divider(),

              Expanded(
                child: ListView.builder(
                  itemCount: ingredientMaster.length,
                  itemBuilder: (_, i) {
                    final ingredient = ingredientMaster[i];

                    return ListTile(
                      title: Text(ingredient["name"]),
                      onTap: () {
                        setState(() {
                          ingredients[rowIndex]["ingredientId"] =
                              ingredient["id"];

                          ingredients[rowIndex]["ingredientName"] =
                              ingredient["name"];

                          ingredients[rowIndex]["unitRate"] =
                              (ingredient["cost"] as num?)?.toDouble() ?? 0;
                        });

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
