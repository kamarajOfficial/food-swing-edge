import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class PurchaseRequestCreatePage extends StatefulWidget {
  final String companyId;

  const PurchaseRequestCreatePage({super.key, required this.companyId});

  @override
  State<PurchaseRequestCreatePage> createState() =>
      _PurchaseRequestCreatePageState();
}

class _PurchaseRequestCreatePageState extends State<PurchaseRequestCreatePage> {
  List<String> selectedKitchens = [];

  final List<String> kitchens = [
    "Central Kitchen",
    "Outlet Kitchen",
    "Bakery Kitchen",
  ];

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

  double get totalAmount {
    double total = 0;

    for (var item in items) {
      total += item["qty"] * item["rate"];
    }

    return total;
  }

  @override
  void initState() {
    super.initState();

    fromDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    toDateController.text =
        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";
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
                        child: MultiSelectDialogField<String>(
                          items: kitchens
                              .map((e) => MultiSelectItem<String>(e, e))
                              .toList(),
                          title: const Text("Kitchen"),
                          buttonText: Text(
                            selectedKitchens.isEmpty
                                ? "Kitchen"
                                : selectedKitchens.length == 1
                                ? selectedKitchens.first
                                : "${selectedKitchens.first} +${selectedKitchens.length - 1}",
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

                  const SizedBox(height: 15),

                  /// CATEGORY
                  DropdownButtonFormField<String>(
                    value: category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Icons.category_outlined),
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
                    items: const [
                      DropdownMenuItem(
                        value: "Non Perishable",
                        child: Text("Non Perishable"),
                      ),
                      DropdownMenuItem(
                        value: "Perishable",
                        child: Text("Perishable"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => category = v!);
                    },
                  ),
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
                  onPressed: () {
                    // Open Add Item Screen
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            // const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

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
                                    child: Image.network(
                                      item["image"],
                                      fit: BoxFit.contain,
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
                                      items.removeAt(index);
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
                      "Total Items : ${items.length}",
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
                    onPressed: () {},
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
                    onPressed: () {},
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
