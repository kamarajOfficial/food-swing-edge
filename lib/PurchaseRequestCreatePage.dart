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
  // List<String> selectedKitchens = [];
  List<Map<String, dynamic>> kitchens = [];

  Map<String, dynamic>? selectedKitchen;
  List<Map<String, dynamic>> availableIngredients = [];

  List<Map<String, dynamic>> selectedIngredients = [];
  int? createdPrId;

  // final List<String> kitchens = [
  //   "Central Kitchen",
  //   "Outlet Kitchen",
  //   "Bakery Kitchen",
  // ];

  List<String> selectedMeals = [];

  final List<String> meals = ["Breakfast", "Lunch", "Dinner", "Snacks"];
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
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                List<Map<String, dynamic>> filteredIngredients =
                List.from(availableIngredients);

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xfff8f9fd),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Select Ingredient",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search ingredient...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              filteredIngredients = availableIngredients
                                  .where(
                                    (e) => e["ingredientName"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                                  .toList();
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final item = filteredIngredients[index];

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.pop(context);
                                  addIngredient(item);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 55,
                                        width: 55,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                          BorderRadius.circular(15),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2,
                                          color: Colors.orange,
                                          size: 28,
                                        ),
                                      ),

                                      const SizedBox(width: 15),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item["ingredientName"],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            Text(
                                              item["code"],
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                    Colors.green.shade50,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                                  ),
                                                  child: Text(
                                                    "Stock ${item["netAvailableStock"]}",
                                                    style: TextStyle(
                                                      color:
                                                      Colors.green.shade700,
                                                      fontSize: 11,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 8),

                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                    Colors.orange.shade50,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                                  ),
                                                  child: Text(
                                                    item["uomName"],
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₹${item["estimatedUnitPrice"]}",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepOrange,
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "ADD",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  void addIngredient(Map<String, dynamic> ingredient) {
    if (selectedIngredients.any(
      (e) => e["ingredientId"] == ingredient["ingredientId"],
    )) {
      return;
    }

    setState(() {
      selectedIngredients.add({
        "ingredientId": ingredient["ingredientId"],

        "name": ingredient["ingredientName"],

        "qty": 1,

        "rate": ingredient["estimatedUnitPrice"],

        "uom": ingredient["uomName"],

        "stock": ingredient["netAvailableStock"],
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

    final body = {"remarks": remarksController.text, "actionBy": "PR"};

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

    if (selectedMeals.isEmpty) {
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
      "mealIds": selectedMeals.map((e) => int.parse(e)).toList(),

      "companyIds": [int.parse(widget.companyId)],

      "fromDate": formatApiDate(fromDateController.text),
      "toDate": formatApiDate(toDateController.text),
      "requiredByDate": formatApiDate(toDateController.text),

      "priority": "Medium",
      "requestType": "Manual",
      "source": "Production Plan",
      "remarks": remarksController.text,
      "actionBy": "PR",

      "ingredients": selectedIngredients
          .map((e) => {"ingredientId": e["ingredientId"], "quantity": e["qty"]})
          .toList(),
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

  @override
  void initState() {
    super.initState();

    fromDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    toDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    loadKitchens();
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
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
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

                  const SizedBox(height: 10),

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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// KITCHEN & MEAL
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedKitchen,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Kitchen",
                            prefixIcon: const Icon(Icons.restaurant),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          items: kitchens.map((kitchen) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: kitchen,
                              child: Text(kitchen["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedKitchen = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        child: MultiSelectDialogField<String>(
                          items: meals
                              .map((e) => MultiSelectItem<String>(e, e))
                              .toList(),
                          title: const Text("Meal"),

                          buttonText: Text(
                            selectedMeals.isEmpty
                                ? "Meal"
                                : selectedMeals.length == 1
                                ? selectedMeals.first
                                : "${selectedMeals.first} +${selectedMeals.length - 1}",
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

            // const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedIngredients.length,
                itemBuilder: (context, index) {
                  final item = selectedIngredients[index];

                  return Container(
                    width: 210,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(.12),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              /// Center Image
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      size: 40,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ),

                              /// Delete Button
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedIngredients.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            item["name"],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // const SizedBox(height: 6),

                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 12, vertical: 5),
                          //   decoration: BoxDecoration(
                          //     color: Colors.green.shade50,
                          //     borderRadius: BorderRadius.circular(20),
                          //   ),
                          // child: Text(
                          //   item["stock"],
                          //   style: TextStyle(
                          //     color: Colors.green.shade700,
                          //     fontWeight: FontWeight.bold,
                          //     fontSize: 8,
                          //   ),
                          // ),
                          // ),
                          const SizedBox(height: 10),

                          Text(
                            "₹${item["rate"]}/${item["uom"]}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "₹${item["qty"] * item["rate"]}",
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          // const Spacer(),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (item["qty"] > 1) {
                                      setState(() {
                                        item["qty"]--;
                                      });
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    "${item["qty"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      item["qty"]++;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Icon(Icons.add, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Card(
              color: Colors.orange.shade50,
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

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saveDraft,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Draft"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: submitPR,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit PR"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
