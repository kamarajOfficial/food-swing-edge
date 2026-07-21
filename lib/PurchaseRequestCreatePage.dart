import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'dart:convert';

import 'package:foodswing_flutter/config_loader.dart';
import 'package:http/http.dart' as http;

class PurchaseRequestCreatePage extends StatefulWidget {
  final String companyId;

  const PurchaseRequestCreatePage({super.key, required this.companyId});

  @override
  State<PurchaseRequestCreatePage> createState() =>
      _PurchaseRequestCreatePageState();
}

class _PurchaseRequestCreatePageState extends State<PurchaseRequestCreatePage> {
  List<Map<String, dynamic>> kitchens = [];

  Map<String, dynamic>? selectedKitchen;
  List<Map<String, dynamic>> availableIngredients = [];

  List<Map<String, dynamic>> selectedIngredients = [];
  int? createdPrId;

  List<String> selectedMeals = [];
  String selectedFilter = "All";
  String searchText = "";
  List<Map<String, dynamic>> meals = [];
  List<int> selectedMealIds = [];

  String source = "Production Plan";
  String kitchen = "Central Kitchen";
  String meal = "Breakfast";
  String category = "Non Perishable";

  DateTime selectedDate = DateTime.now();
  DateTime requiredDate = DateTime.now();

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  final List<Map<String, dynamic>> items = [
    {
      "name": "Rice",
      "qty": 50,
      "uom": "Kg",
      "rate": 50,
      "image": "https://cdn-icons-png.flaticon.com/512/3082/3082037.png",
      "stock": "Available",
    },
    {
      "name": "Sugar",
      "qty": 25,
      "uom": "Kg",
      "rate": 42,
      "image": "https://cdn-icons-png.flaticon.com/512/1046/1046857.png",
      "stock": "Available",
    },
    {
      "name": "Tomato",
      "qty": 15,
      "uom": "Kg",
      "rate": 35,
      "image": "https://cdn-icons-png.flaticon.com/512/590/590685.png",
      "stock": "Fresh",
    },
  ];

  Future<void> loadKitchens() async {
    final response = await http.get(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/kitchenByCompany/${widget.companyId}",
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        kitchens = List<Map<String, dynamic>>.from(json["data"]);
      });
    }
  }

  Future<void> loadIngredients() async {
    if (selectedKitchen == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Kitchen")));
      return;
    }

    final kitchenId = selectedKitchen!["id"];

    final response = await http.get(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/kitchens/ingredients/dropdown/$kitchenId",
      ),
    );
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        availableIngredients = List<Map<String, dynamic>>.from(json["data"]);
      });

      print("Ingredients Count : ${availableIngredients.length}");

      openIngredientBottomSheet();
    }
  }

  void openIngredientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<Map<String, dynamic>> filtered = availableIngredients.where((
              e,
            ) {
              final stock =
                  double.tryParse(e["netAvailableStock"].toString()) ?? 0;

              bool filter = true;

              if (selectedFilter == "Low Stock") {
                filter = stock <= 20;
              } else if (selectedFilter == "High Stock") {
                filter = stock > 20;
              }

              bool search =
                  e["ingredientName"].toString().toLowerCase().contains(
                    searchText.toLowerCase(),
                  ) ||
                  e["code"].toString().toLowerCase().contains(
                    searchText.toLowerCase(),
                  );

              return filter && search;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: .90,
              maxChildSize: .95,
              minChildSize: .60,
              expand: false,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 15, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Select Ingredient",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search ingredient by name / code",
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.orange.shade300,
                                width: 1.2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              searchText = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            filterChip("All", setSheetState),
                            const SizedBox(width: 6),
                            filterChip("Low Stock", setSheetState),
                            const SizedBox(width: 6),
                            filterChip("High Stock", setSheetState),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.grey.shade200, height: 1),
                          itemBuilder: (_, index) {
                            final item = filtered[index];

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),

                              leading: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.orange,
                                ),
                              ),

                              title: Text(
                                item["ingredientName"],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item["code"].toString()),

                                  Text(
                                    "Stock : ${item["netAvailableStock"]}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              trailing: SizedBox(
                                width: 85,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${item["estimatedUnitPrice"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        addIngredient(item);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF010440),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: const Color(0xFF010440),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget filterChip(String title, StateSetter setSheetState) {
    final selected = selectedFilter == title;

    return GestureDetector(
      onTap: () {
        setSheetState(() {
          selectedFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF010440) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void addIngredient(Map<String, dynamic> ingredient) {
    if (selectedIngredients.any(
      (e) => e["ingredientId"] == ingredient["ingredientId"],
    )) {
      return;
    }

    setState(() {
      selectedIngredients.add({
        "ingredientId": ingredient["ingredientId"],
        "ingredientName": ingredient["ingredientName"],
        "ingredientCode": ingredient["code"],

        "uomId": ingredient["uomId"],
        "uomName": ingredient["uomName"],

        "ingredientTypeId": ingredient["ingredientTypeId"],
        "ingredientTypeName": ingredient["ingredientTypeName"],

        "perishableType": ingredient["perishableType"],

        // quantity editable by user
        "qty": 1,

        // values from Kitchen Ingredient API
        "availableStock":
            ingredient["availableStock"] ??
            ingredient["netAvailableStock"] ??
            0,

        "reservedStock": ingredient["reservedStock"] ?? 0,

        "pendingPoQty": ingredient["pendingPoQty"] ?? 0,

        "netRequiredQty": ingredient["netRequiredQty"] ?? 0,

        "estimatedUnitPrice": (ingredient["estimatedUnitPrice"] ?? 0)
            .toDouble(),

        "estimatedAmount": (ingredient["estimatedAmount"] ?? 0).toDouble(),

        "remarks": "",

        "sourceType": ingredient["sourceType"],

        "sourceDate": ingredient["sourceDate"],

        "orderDate": ingredient["orderDate"],

        "originalOrderDates": ingredient["originalOrderDates"],

        "mealId": ingredient["mealId"],

        "mealName": ingredient["mealName"],

        "productionPlanItems": ingredient["productionPlanItems"],

        // for UI
        "name": ingredient["ingredientName"],
        "uom": ingredient["uomName"],
        "rate": (ingredient["estimatedUnitPrice"] ?? 0).toDouble(),
        "stock": ingredient["netAvailableStock"] ?? 0,
      });
    });
  }

  double get totalAmount {
    double total = 0;

    for (var item in selectedIngredients) {
      total += item["qty"] * item["rate"];
    }

    return total;
  }

  Future<void> submitPR() async {
    if (createdPrId == null) {
      await saveDraft();

      if (createdPrId == null) {
        return;
      }
    }

    final body = {"remarks": remarksController.text, "actionBy": "Mobile PR"};

    final response = await http.put(
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/submit/$createdPrId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print(response.body);

    if (response.statusCode == 200) {
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

  String formatApiDate(String value) {
    final p = value.split("-");
    return "${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}";
  }

  Future<void> saveDraft() async {
    if (selectedKitchen == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Kitchen")));
      return;
    }

    if (selectedMealIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Meal")));
      return;
    }

    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one ingredient")),
      );
      return;
    }

    final body = {
      "kitchenId": selectedKitchen!["id"],

      // Replace with actual meal ids from your API
      "mealIds": selectedMealIds,

      "companyIds": [int.parse(widget.companyId)],

      "fromDate": formatApiDate(fromDateController.text),
      "toDate": formatApiDate(toDateController.text),
      "requiredByDate": formatApiDate(toDateController.text),

      "priority": "Medium",
      "requestType": "Manual",
      "source": source,
      "remarks": remarksController.text,
      "actionBy": "Mobile PR",

      "ingredients": selectedIngredients.map((e) {
        return {
          "ingredientId": e["ingredientId"],
          "ingredientName": e["ingredientName"],
          "ingredientCode": e["ingredientCode"],
          "uomId": e["uomId"],
          "uomName": e["uomName"],
          "ingredientTypeId": e["ingredientTypeId"],
          "ingredientTypeName": e["ingredientTypeName"],
          "perishableType": e["perishableType"],
          "requiredQty": e["qty"],
          "availableStock": e["availableStock"],
          "reservedStock": e["reservedStock"],
          "pendingPoQty": e["pendingPoQty"],
          "netRequiredQty": e["netRequiredQty"],
          "estimatedUnitPrice": e["estimatedUnitPrice"],
          "estimatedAmount":
              ((e["qty"] ?? 0) as num).toDouble() *
              ((e["estimatedUnitPrice"] ?? 0) as num).toDouble(),
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

    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);

      createdPrId = json["data"]["prId"];

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(json["status"]["message"])));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));
    }
  }

  void openMealDialog() async {
    List<int> tempSelected = List.from(selectedMealIds);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),

            title: Column(
              children: [
                const Text(
                  "Select Meal",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          tempSelected = meals
                              .map<int>((e) => e["id"] as int)
                              .toList();
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

                const Divider(height: 1),
              ],
            ),

            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (_, index) {
                  final meal = meals[index];

                  return CheckboxListTile(
                    dense: true,
                    value: tempSelected.contains(meal["id"]),
                    title: Text(meal["name"]),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setStateDialog(() {
                        if (value!) {
                          tempSelected.add(meal["id"]);
                        } else {
                          tempSelected.remove(meal["id"]);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedMealIds = List.from(tempSelected);
                  });

                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    fromDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    toDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    loadKitchens();
    loadMeals();
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
      appBar: AppBar(
        title: const Text("Create PR"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  /// SOURCE
                  DropdownButtonFormField<String>(
                    value: source,
                    isDense: true,
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

                  const SizedBox(height: 12),

                  /// FROM & TO
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fromDateController,
                          readOnly: true,
                          onTap: () => _pickDate(true),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "From Date",
                            isDense: true,
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: toDateController,
                          readOnly: true,
                          onTap: () => _pickDate(false),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "To Date",
                            isDense: true,
                            prefixIcon: const Icon(Icons.event, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Kitchen & Meal
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedKitchen,
                          isExpanded: true,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: "Kitchen",
                            prefixIcon: const Icon(Icons.restaurant, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: kitchens.map((kitchen) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: kitchen,
                              child: Text(
                                kitchen["name"],
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedKitchen = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: InkWell(
                          onTap: openMealDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fastfood, size: 18),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    selectedMealIds.isEmpty
                                        ? "Meal"
                                        : "${selectedMealIds.length} Selected",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),

                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  //       const SizedBox(height: 15),
                  //
                  //       /// CATEGORY
                  //       DropdownButtonFormField<String>(
                  //         value: category,
                  //         isExpanded: true,
                  //         decoration: InputDecoration(
                  //           labelText: "Category",
                  //           prefixIcon: const Icon(Icons.category_outlined),
                  //           filled: true,
                  //           fillColor: Colors.white,
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(18),
                  //           ),
                  //           enabledBorder: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(18),
                  //             borderSide: BorderSide(color: Colors.grey.shade300),
                  //           ),
                  //         ),
                  //         items: const [
                  //           DropdownMenuItem(
                  //             value: "Non Perishable",
                  //             child: Text("Non Perishable"),
                  //           ),
                  //           DropdownMenuItem(
                  //             value: "Perishable",
                  //             child: Text("Perishable"),
                  //           ),
                  //         ],
                  //         onChanged: (v) {
                  //           setState(() => category = v!);
                  //         },
                  //       ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: loadIngredients,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            // const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedIngredients.length,
                itemBuilder: (context, index) {
                  final item = selectedIngredients[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Image Area
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),

                              /// Minus Button
                              Positioned(
                                bottom: -8,
                                child: Container(
                                  height: 30,
                                  width: 85,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      /// Minus
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              item["qty"]--;

                                              if (item["qty"] <= 0) {
                                                selectedIngredients.removeAt(
                                                  index,
                                                );
                                              }
                                            });
                                          },
                                          child: const Center(
                                            child: Icon(
                                              Icons.remove,
                                              size: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),

                                      /// Qty
                                      SizedBox(
                                        width: 28,
                                        child: Center(
                                          child: Text(
                                            "${item["qty"]}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),

                                      /// Plus
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              item["qty"]++;
                                            });
                                          },
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              size: 16,
                                              color: Color(0xFF010440),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // const SizedBox(height: 28),

                          /// UOM
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //     horizontal: 10,
                          //     vertical: 5,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey.shade200,
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: Text(
                          //     item["uom"],
                          //     style: const TextStyle(
                          //       fontSize: 8,
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 25),

                          /// Name
                          Text(
                            item["name"],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            "₹${(item["qty"] * item["rate"]).toStringAsFixed(2)} / ${item["uom"]}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 50),

            Card(
              color: Colors.white60,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Items : ${selectedIngredients.length}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Text(
                      "₹${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: saveDraft,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "Save Draft",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // const SizedBox(width: 10),

                // Expanded(
                //   child: ElevatedButton.icon(
                //     style: ElevatedButton.styleFrom(
                //       // backgroundColor: const Color(0xFF010440),
                //       backgroundColor: const Color(0xFFF15F28),
                //     ),
                //     onPressed: submitPR,
                //     icon: const Icon(Icons.send, color: Colors.white),
                //     label: const Text(
                //       "Submit PR",
                //       style: TextStyle(
                //         color: Colors.white,
                //         fontWeight: FontWeight.w600,
                //       ),
                //      ),
                //    ),
                // ),
              ],
            ),

            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
