import 'package:flutter/material.dart';

import 'PurchaseRequestDetailsPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodswing_flutter/config_loader.dart';

class PurchaseRequestListPage extends StatefulWidget {
  final String companyId;

  const PurchaseRequestListPage({Key? key, required this.companyId})
    : super(key: key);

  @override
  State<PurchaseRequestListPage> createState() =>
      _PurchaseRequestListPageState();
}

class _PurchaseRequestListPageState extends State<PurchaseRequestListPage> {
  // final List<String> filters = ["All", "Pending", "Approved", "Rejected"];

  final TextEditingController searchController = TextEditingController();

  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  List<Map<String, dynamic>> prList = [];
  List<Map<String, dynamic>> filteredList = [];

  final List<String> filters = [
    "All",
    "DRAFT",
    "DENIED",
    "APPROVED",
    "PARTIAL PO",
  ];

  String selectedFilter = "All";

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadPurchaseRequests();
  }

  String formatDate(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadPurchaseRequests() async {
    setState(() {
      loading = true;
    });

    String status = selectedFilter == "All" ? "" : selectedFilter;

    final body = {
      "page": 1,
      "size": 100,
      "companyId": int.parse(widget.companyId),
      "status": status.isEmpty ? null : status,
      // "fromDate": formatDate(fromDate),
      // "toDate": formatDate(toDate),
      "prNumber": searchController.text.trim().isEmpty
          ? null
          : searchController.text.trim(),
    };

    print("========== PR SEARCH REQUEST ==========");
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("========== PR SEARCH RESPONSE ==========");
    print("Status Code: ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      prList = List<Map<String, dynamic>>.from(json["data"]);

      filteredList = List.from(prList);
    } else {
      print("Request Failed");
      print(response.body);
    }

    setState(() {
      loading = false;
    });
  }

  void searchPR(String value) {
    setState(() {
      filteredList = prList.where((e) {
        return e["prNumber"].toString().toLowerCase().contains(
          value.toLowerCase(),
        );
      }).toList();
    });
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,

      initialDate: isFrom ? fromDate : toDate,

      firstDate: DateTime(2025),

      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });

      loadPurchaseRequests();
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "APPROVED":
        return Colors.green;

      case "PARTIAL PO":
        return Colors.blue;

      case "DENIED":
        return Colors.red;

      case "DRAFT":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PR List"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.orange,
      //   onPressed: () {
      //     // Navigate to Create Purchase Request
      //   },
      //   child: const Icon(Icons.add),
      // ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: searchPR,
              decoration: InputDecoration(
                hintText: "Search PR Number, Source, Kitchen...",
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
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final filter = filters[index];

                final count = filter == "All"
                    ? prList.length
                    : prList.where((e) => e["status"] == filter).length;

                final selected = selectedFilter == filter;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });

                    loadPurchaseRequests();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$filter ($count)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF2457F5)
                              : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: selected ? 40 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2457F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredList.length,

                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PurchaseRequestDetailsPage(
                                companyId: widget.companyId,
                                prId: item["prId"],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// PR Number + Status
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["prNumber"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(
                                        item["status"],
                                      ).withOpacity(.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item["status"],
                                      style: TextStyle(
                                        color: getStatusColor(item["status"]),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// Source | Kitchen | Meal
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 15,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(width: 5),

                                  Expanded(
                                    child: Text(
                                      "${item["source"]}   •   ${item["kitchenName"]}   •   ${item["mealNames"]}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// Date
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 15,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(width: 5),

                                  Text(
                                    "${item["fromDate"]}  -  ${item["toDate"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// Items + Amount
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 15,
                                    color: Colors.grey,
                                  ),

                                  const SizedBox(width: 5),

                                  Text(
                                    "${item["totalItems"] ?? 0} Items",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  const Icon(
                                    Icons.currency_rupee,
                                    size: 15,
                                    color: Colors.grey,
                                  ),

                                  Text(
                                    "${item["estimatedAmount"] ?? 0}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
  }
}

class PurchaseRequestDetailsPage extends StatefulWidget {
  final String companyId;
  final int prId;

  const PurchaseRequestDetailsPage({
    Key? key,
    required this.companyId,
    required this.prId,
  }) : super(key: key);

  @override
  State<PurchaseRequestDetailsPage> createState() =>
      _PurchaseRequestDetailsPageState();
}

class _PurchaseRequestDetailsPageState
    extends State<PurchaseRequestDetailsPage> {
  Map<String, dynamic>? prDetails;
  bool loading = true;
  List<Map<String, dynamic>> ingredientMaster = [];
  List<Map<String, dynamic>> ingredients = [];
  Map<int, Map<String, dynamic>> ingredientMap = {};
  bool showItems = false;

  @override
  void initState() {
    super.initState();
    loadIngredients();
    loadPRDetails();
  }

  Future<void> loadIngredients() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/ingredientAllGet/list"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        ingredientMaster = List<Map<String, dynamic>>.from(json["data"]);

        ingredientMap = {
          for (var item in ingredientMaster) item["id"] as int: item,
        };
      });
    }
  }

  Future<void> loadPRDetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/${widget.prId}"),
    );

    print("Status Code: ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        prDetails = json["data"];

        ingredients = List<Map<String, dynamic>>.from(
          json["data"]["ingredients"],
        );

        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  String formatDate(String date) {
    final d = DateTime.parse(date);

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${d.day.toString().padLeft(2, '0')} "
        "${months[d.month - 1]} "
        "${d.year}";
  }

  double get totalQty {
    double qty = 0;

    for (var item in ingredients) {
      qty += ((item["requiredQty"] ?? 0) as num).toDouble();
    }

    return qty;
  }

  double get totalAmount {
    double amount = 0;

    for (var item in ingredients) {
      amount += ((item["estimatedAmount"] ?? 0) as num).toDouble();
    }

    return amount;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (prDetails == null) {
      return const Scaffold(body: Center(child: Text("No Data Found")));
    }
    final requisition = prDetails!["requisition"];

    return Scaffold(
      appBar: AppBar(
        title: Text("PR List"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Header
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            requisition["prNumber"],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            requisition["status"],
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    detailRow("Source", requisition["source"] ?? ""),

                    detailRow(
                      "Kitchen",
                      "FPU", // API kitchen name
                    ),

                    detailRow(
                      "Meal",
                      "Dinner", // API meal name
                    ),

                    detailRow(
                      "Date Range",
                      "${formatDate(requisition["fromDate"])} - ${formatDate(requisition["toDate"])}",
                    ),

                    detailRow("Created By", requisition["createdBy"]),

                    detailRow(
                      "Created On",
                      requisition["createdAt"].toString().replaceFirst(
                        "T",
                        " ",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: summary(
                        requisition["totalItems"].toString(),
                        "Items",
                      ),
                    ),

                    Container(
                      height: 45,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    Expanded(
                      child: summary(totalQty.toStringAsFixed(2), "Qty"),
                    ),

                    Container(
                      height: 45,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),

                    Expanded(
                      child: summary(
                        "₹${totalAmount.toStringAsFixed(2)}",
                        "Amount",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        showItems = !showItems;
                      });
                    },
                    child: Text(showItems ? "Hide Items" : "View Items"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Generate PO"),
                  ),
                ),
              ],
            ),

            /// Ingredient Table
            if (showItems)
              Card(
                elevation: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 10,
                    horizontalMargin: 8,
                    dataRowMinHeight: 42,
                    dataRowMaxHeight: 42,
                    headingRowHeight: 38,
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 12),
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF15F28),
                    ),
                    columns: const [
                      DataColumn(label: Text("Ingredient")),
                      DataColumn(label: Text("Qty")),
                      DataColumn(label: Text("Cost")),
                      DataColumn(label: Text("Rate")),
                      DataColumn(label: Text("")),
                    ],
                    rows: ingredients.map<DataRow>((item) {
                      final ingredient = ingredientMap[item["ingredientId"]];
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
                                  value: ingredient,
                                  hint: Text(
                                    ingredient?["name"] ?? "Select Ingredient",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  items: ingredientMaster.map((ingredient) {
                                    return DropdownMenuItem<
                                      Map<String, dynamic>
                                    >(
                                      value: ingredient,
                                      child: Text(
                                        ingredient["name"],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (selected) {
                                    if (selected == null) return;

                                    setState(() {
                                      item["ingredientId"] = selected["id"];

                                      final parts = selected["name"]
                                          .toString()
                                          .split(" - ");

                                      item["ingredientName"] = parts.first;
                                      item["erpId"] = parts.length > 1
                                          ? parts.last
                                          : "";

                                      item["unitRate"] =
                                          (selected["cost"] as num).toDouble();

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
                                initialValue: item["requiredQty"].toString(),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (value) {
                                  setState(() {
                                    item["requiredQty"] =
                                        double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ),

                          /// Cost
                          DataCell(
                            SizedBox(
                              width: 65,
                              child: Text(
                                "₹${((item["estimatedAmount"] ?? 0) as num).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                          /// Rate
                          DataCell(
                            SizedBox(
                              width: 55,
                              child: Text(
                                "₹${((item["estimatedUnitPrice"] ?? 0) as num).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                          /// Delete
                          DataCell(
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 18,
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
            // const SizedBox(height: 10),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFFF15F28),
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     ),
            //
            //     icon: const Icon(Icons.save),
            //
            //     label: const Text(
            //       "Save Purchase Request",
            //       style: TextStyle(fontSize: 16),
            //     ),
            //
            //     onPressed: savePR,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> savePR() async {
    final body = {
      "kitchenId": prDetails!["kitchenId"],
      "fromDate": prDetails!["fromDate"],
      "toDate": prDetails!["toDate"],
      "requiredByDate": prDetails!["requiredByDate"],
      "priority": prDetails!["priority"],
      "requestType": prDetails!["requestType"],
      "source": prDetails!["source"],
      "remarks": prDetails!["remarks"],
      "actionBy": prDetails!["modifiedBy"] ?? "mobile",
      "ingredients": ingredients
          .map(
            (e) => {
              "ingredientId": e["ingredientId"],
              // "quantity": e["quantity"],
              "requiredQty": e["requiredQty"],
            },
          )
          .toList(),
    };

    final response = await http.put(
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/updateDraft/${widget.prId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

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

  Widget summary(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFFF15F28)),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),

        const SizedBox(height: 5),

        Text(title),
      ],
    );
  }
}
