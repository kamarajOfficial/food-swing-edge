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
    "APPROVED",
    "PARTIAL PO",
    "DENIED",
    "DRAFT",
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

    final url =
        "${AppConfig.apiBaseUrl}"
        "/api/getAllPrNumber/"
        "${formatDate(fromDate)}/"
        "${formatDate(toDate)}"
        "?status=$status";

    print(url);

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      prList = List<Map<String, dynamic>>.from(json["data"]);

      filteredList = List.from(prList);
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
                hintText: "Search PR Number...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                // fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),

                    label: Text(formatDate(fromDate)),

                    onPressed: () => pickDate(true),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),

                    label: Text(formatDate(toDate)),

                    onPressed: () => pickDate(false),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selectedFilter == filter,
                    selectedColor: Color(0xFFF15F28),
                    labelStyle: TextStyle(
                      color: selectedFilter == filter
                          ? Colors.white
                          : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter;
                      });
                      loadPurchaseRequests();
                    },
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

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.description,
                              color: Color(0xFFF15F28),
                            ),
                          ),

                          title: Text(item["prNumber"]),

                          subtitle: Text(
                            "${item["fromDate"]}  →  ${item["toDate"]}",
                          ),

                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            crossAxisAlignment: CrossAxisAlignment.end,

                            children: [
                              Text(
                                "₹${item["totalCost"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),

                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    item["status"],
                                  ).withOpacity(.15),

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

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => PurchaseRequestDetailsPage(
                                  companyId: widget.companyId,
                                  prNumber: item["prNumber"],
                                ),
                              ),
                            );
                          },
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
  final String prNumber;

  const PurchaseRequestDetailsPage({
    Key? key,
    required this.companyId,
    required this.prNumber,
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
        ingredientMaster =
        List<Map<String, dynamic>>.from(json["data"]);
      });
    }
  }

  Future<void> loadPRDetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/getByPrNumber/${widget.prNumber}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        prDetails = json["data"];

        ingredients = List<Map<String, dynamic>>.from(
          prDetails!["ingredients"],
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
      qty += (item["quantity"] ?? 0).toDouble();
    }

    return qty;
  }

  double get totalAmount {
    double amount = 0;

    for (var item in ingredients) {
      amount +=
          (item["quantity"] ?? 0).toDouble() *
          (item["unitRate"] ?? 0).toDouble();
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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          prDetails!["prNumber"],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            prDetails!["status"],
                            style: const TextStyle(
                              color: Color(0xFFF15F28),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    infoRow(
                      Icons.calendar_today,
                      "Date Range",
                      "${formatDate(prDetails!["fromDate"])} - ${formatDate(prDetails!["toDate"])}",
                    ),

                    infoRow(
                      Icons.person,
                      "Created By",
                      "${prDetails!["createdBy"]} • ${formatDate(prDetails!["createdTime"].substring(0, 10))}",
                    ),

                    infoRow(Icons.fastfood, "Meals", prDetails!["mealNames"]),

                    infoRow(
                      Icons.restaurant,
                      "Kitchen",
                      prDetails!["kitchenNames"],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Summary
            Card(
              // color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    summaryItem("Items", ingredients.length.toString()),

                    summaryItem("Qty", totalQty.toStringAsFixed(2)),

                    summaryItem("Amount", "₹${totalAmount.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Ingredient Table
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
                  rows: (prDetails!["ingredients"] as List).map<DataRow>((
                    item,
                  ) {
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
                                value:
                                    ingredientMaster.any(
                                      (e) =>
                                          e["id"].toString() ==
                                          item["ingredientId"].toString(),
                                    )
                                    ? ingredientMaster.firstWhere(
                                        (e) =>
                                            e["id"].toString() ==
                                            item["ingredientId"].toString(),
                                      )
                                    : null,
                                hint: Text(
                                  "${item["ingredientName"]}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                items: ingredientMaster.map((ingredient) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
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

                                    item["unitRate"] = (selected["cost"] as num)
                                        .toDouble();

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
                              onChanged: (value) {
                                setState(() {
                                  item["quantity"] =
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
                              "₹${((item["quantity"] ?? 0) * (item["unitRate"] ?? 0)).toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),

                        /// Rate
                        DataCell(
                          SizedBox(
                            width: 55,
                            child: Text(
                              "₹${(item["unitRate"] as num).toStringAsFixed(0)}",
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15F28),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),

                icon: const Icon(Icons.save),

                label: const Text(
                  "Save Purchase Request",
                  style: TextStyle(fontSize: 16),
                ),

                onPressed: savePR,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> savePR() async {
    final body = {
      "prNumber": prDetails!["prNumber"],
      "ingredients": ingredients,
    };

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/savePurchaseRequest"),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Purchase Request Saved")));
    }
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
