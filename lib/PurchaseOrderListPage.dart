import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodswing_flutter/config_loader.dart';

class PurchaseOrderListPage extends StatefulWidget {
  final String companyId;

  const PurchaseOrderListPage({Key? key, required this.companyId})
    : super(key: key);

  @override
  State<PurchaseOrderListPage> createState() =>
      _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends State<PurchaseOrderListPage> {
  // final List<String> filters = ["All", "Pending", "Approved", "Rejected"];

  final TextEditingController searchController = TextEditingController();

  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  List<Map<String, dynamic>> prList = [];
  List<Map<String, dynamic>> filteredList = [];

  final List<String> filters = [
    "All",
    "DRAFT",
    "SUBMITTED",
    "APPROVED",
    "REJECTED",
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

    print("========== PO SEARCH REQUEST ==========");
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("========== PO SEARCH RESPONSE ==========");
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

      case "SUBMITTED":
        return Colors.blue;

      case "REJECTED":
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
        title: const Text("PO List"),
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
                hintText: "Search PO Number, Source, Kitchen...",
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
                              ? const Color(0xFF010440)
                              : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: selected ? 40 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF010440),
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
  Map<int, String> ingredientNameMap = {};
  bool showItems = false;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadIngredients(), loadPRDetails()]);

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
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
        ingredientNameMap = {
          for (final item in ingredientMaster)
            item["id"] as int: item["name"].toString(),
        };
      });
    }
  }

  Future<void> loadPRDetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/${widget.prId}"),
    );

    print("Status Code: ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      prDetails = json["data"];

      ingredients = List<Map<String, dynamic>>.from(
        json["data"]["ingredients"],
      );
    } else {
      setState(() {});
    }
  }

  Future<void> updateStatus({
    required String endpoint,
    required String successMessage,
  }) async {
    final body = {
      "remarks": "",
      "actionBy": prDetails!["requisition"]["modifiedBy"] ?? "mobile",
    };
    print("========== UPDATE STATUS ==========");
    print("${AppConfig.apiBaseUrl}/api/po/$endpoint/${widget.prId}");
    print(jsonEncode(body));

    final response = await http.put(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/$endpoint/${widget.prId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("Status : ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      await loadAll();

      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));
    }
  }

  Future<void> generatePO() async {
    final requisition = prDetails!["requisition"];

    final body = {
      "vendorId": requisition["vendorId"], // Select vendor if not available
      "kitchenId": requisition["kitchenId"],
      "companyId": requisition["companyId"],
      "deliveryAddress": requisition["deliveryAddress"] ?? "",
      "countryCode": "IN",
      "currencyCode": "INR",
      "orderDate": DateTime.now().toIso8601String().split("T")[0],
      "expectedDeliveryDate":
          requisition["requiredByDate"] ??
          DateTime.now().toIso8601String().split("T")[0],
      "remarks": requisition["remarks"] ?? "",
      "taxType": "EXCLUSIVE",
      "taxPercentage": 0,
      "shippingAmount": 0,
      "otherCharges": 0,
      "actionBy": requisition["modifiedBy"] ?? "mobile",

      "items": ingredients.map((item) {
        return {
          "prIngredientId": item["id"],
          "ingredientId": item["ingredientId"],
          "ingredientName": ingredientMap[item["ingredientId"]]?["name"] ?? "",
          "ingredientTypeId": item["ingredientTypeId"],
          "ingredientTypeName": item["ingredientTypeName"],
          "uomId": item["uomId"],
          "uomName": item["uomName"],
          "requiredQty": item["requiredQty"],
          "orderedQty": item["requiredQty"],
          "unitPrice": item["estimatedUnitPrice"],
          "discountPercentage": 0,
          "taxType": "EXCLUSIVE",
          "taxPercentage": 0,
          "taxInclusive": false,
          "taxSource": "NONE",
          "remarks": "",
        };
      }).toList(),
    };

    print("========= GENERATE PO =========");
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/po/generate-from-pr/${widget.prId}",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 201) {
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
    final status = requisition["status"];

    return Scaffold(
      appBar: AppBar(
        title: Text("PO List"),
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

                    // detailRow(
                    //   "Meal",
                    //   "Dinner", // API meal name
                    // ),
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
                    onPressed: () {
                      setState(() {
                        showItems = !showItems;
                      });
                    },
                    child: Text(showItems ? "Hide Items" : "View Items"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(child: buildActionButton(status)),
              ],
            ),

            /// Ingredient Table
            if (showItems)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ingredients.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = ingredients[index];

                    final ingredient = ingredientMap[item["ingredientId"]];

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(
                        ingredient?["name"] ?? "Unknown Ingredient",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text("Qty : ${item["requiredQty"]}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${item["estimatedAmount"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Rate ₹${item["estimatedUnitPrice"]}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  Widget buildActionButton(String status) {
    print(status);
    switch (status) {
      case "DRAFT":
        return ElevatedButton(
          onPressed: () {
            updateStatus(
              endpoint: "submit",
              successMessage: "Purchase Request Submitted",
            );
          },
          child: const Text("Submit PR"),
        );

      case "SUBMITTED":
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  updateStatus(
                    endpoint: "approve",
                    successMessage: "PR Approved",
                  );
                },
                child: const Text(
                  "Approve",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  updateStatus(
                    endpoint: "reject",
                    successMessage: "PR Rejected",
                  );
                },
                child: const Text(
                  "Reject",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        );

      case "APPROVED":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF15F28),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GeneratePurchaseOrderPage(
                  prId: widget.prId,
                  // requisition: requisition,
                ),
              ),
            );
          },
          child: const Text("Generate PO"),
        );

      case "REJECTED":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          onPressed: () {
            updateStatus(endpoint: "close", successMessage: "PR Closed");
          },
          child: const Text("Close"),
        );

      case "CLOSED":
        return ElevatedButton(onPressed: null, child: const Text("Closed"));

      default:
        return const SizedBox();
    }
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
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/updateDraft/${widget.prId}"),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

class GeneratePurchaseOrderPage extends StatefulWidget {
  final int prId;

  // final Map<String, dynamic> requisition;

  const GeneratePurchaseOrderPage({
    super.key,
    required this.prId,
    // required this.requisition,
  });

  @override
  State<GeneratePurchaseOrderPage> createState() =>
      _GeneratePurchaseOrderPageState();
}

class _GeneratePurchaseOrderPageState extends State<GeneratePurchaseOrderPage> {
  List<Map<String, dynamic>> eligibleLines = [];
  bool loading = true;
  Map<String, dynamic>? requisition;

  @override
  void initState() {
    super.initState();

    loadPRDetails();

    loadEligibleLines().then((_) {
      loadVendors();
    });
  }

  Future<void> generatePO() async {
    final selectedItems = eligibleLines
        .where((e) => e["selected"] == true)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select atleast one ingredient")),
      );

      return;
    }

    if (selectedItems.any((e) => e["vendorId"] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select vendor for all selected ingredients"),
        ),
      );

      return;
    }

    final today = DateTime.now();
    final requiredDate = DateTime.parse(requisition!["requiredByDate"]);

    final expectedDeliveryDate = requiredDate.isBefore(today)
        ? today
        : requiredDate;

    final body = {
      "vendorId": selectedItems.first["vendorId"],

      "kitchenId": requisition!["kitchenId"],

      "companyId": 76,

      "deliveryAddress": requisition!["deliveryAddress"] ?? "",

      "countryCode": "IN",

      "currencyCode": "INR",

      "orderDate": today.toIso8601String().split("T")[0],

      "expectedDeliveryDate": expectedDeliveryDate.toIso8601String().split(
        "T",
      )[0],

      "remarks": requisition!["remarks"] ?? "",

      "taxType": "EXCLUSIVE",

      "taxPercentage": 0,

      "shippingAmount": 0,

      "otherCharges": 0,

      "actionBy": requisition!["modifiedBy"],

      "items": selectedItems.map((item) {
        return {
          "prIngredientId": item["prIngredientId"],

          "ingredientId": item["ingredientId"],

          "ingredientName": item["ingredientName"],

          "ingredientTypeId": item["ingredientTypeId"],

          "ingredientTypeName": item["ingredientTypeName"],

          "uomId": item["uomId"],

          "uomName": item["uomName"],

          "requiredQty": item["remainingQty"],

          "orderedQty": item["remainingQty"],

          "unitPrice": item["estimatedUnitPrice"],

          "discountPercentage": 0,

          "taxType": "EXCLUSIVE",

          "taxPercentage": 0,

          "taxInclusive": false,

          "taxSource": "NONE",

          "remarks": "",
        };
      }).toList(),
    };

    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse(
        "${AppConfig.apiBaseUrl}/api/po/generate-from-pr/${widget.prId}",
      ),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode(body),
    );

    print(response.body);

    if (response.statusCode == 201) {
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

  Future<void> loadPRDetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/${widget.prId}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      requisition = json["data"]["requisition"];
    }
  }

  Future<void> loadEligibleLines() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/eligible-lines/${widget.prId}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      eligibleLines = List<Map<String, dynamic>>.from(json["data"]);

      for (final item in eligibleLines) {
        item["selected"] = false;
        item["vendorId"] = null;
      }
    }

    setState(() {
      loading = false;
    });
  }

  Map<int, List<dynamic>> vendors = {};

  Future<void> loadVendors() async {
    vendors.clear();

    final types = eligibleLines
        .where((e) => e["selected"])
        .map((e) => e["ingredientTypeId"])
        .toSet();

    for (final typeId in types) {
      final response = await http.get(
        Uri.parse(
          "${AppConfig.apiBaseUrl}/api/po/vendors-by-ingredient-type/$typeId",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        vendors[typeId] = json["data"];
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Purchase Order"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF15F28),
            ),
            onPressed: generatePO,
            child: const Text(
              "Generate Purchase Order",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),

      body: ListView.builder(
        itemCount: eligibleLines.length,
        itemBuilder: (context, index) {
          final item = eligibleLines[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: item["selected"],
                    onChanged: (v) async {
                      setState(() {
                        item["selected"] = v ?? false;
                      });
                      await loadVendors();
                    },
                    title: Text(item["ingredientName"]),
                    subtitle: Text(
                      "${item["remainingQty"]} ${item["uomName"] ?? ""}",
                    ),
                    secondary: Text("₹${item["estimatedUnitPrice"]}"),
                  ),

                  DropdownButtonFormField<int>(
                    value: item["vendorId"],
                    decoration: const InputDecoration(
                      labelText: "Select Vendor",
                    ),
                    items: (vendors[item["ingredientTypeId"]] ?? [])
                        .map<DropdownMenuItem<int>>((vendor) {
                          return DropdownMenuItem<int>(
                            value: vendor["vendorId"],
                            child: Text(vendor["vendorName"]),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      final vendor = (vendors[item["ingredientTypeId"]] ?? [])
                          .firstWhere((v) => v["vendorId"] == value);

                      if ((item["remainingQty"] as num).toDouble() <
                          (vendor["minQty"] as num).toDouble()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Minimum order for ${item["ingredientName"]} is ${vendor["minQty"]}",
                            ),
                          ),
                        );

                        return;
                      }

                      setState(() {
                        item["vendorId"] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
