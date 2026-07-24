import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodswing_flutter/config_loader.dart';

class PurchaseOrderListPage extends StatefulWidget {
  final String companyId;

  const PurchaseOrderListPage({Key? key, required this.companyId})
    : super(key: key);

  @override
  State<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
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
    "ACKNOWLEDGED",
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
      // "companyId": int.parse(widget.companyId),
      "status": status.isEmpty ? null : status,
      // "fromDate": formatDate(fromDate),
      // "toDate": formatDate(toDate),
      "poNumber": searchController.text.trim().isEmpty
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
        return e["poNumber"].toString().toLowerCase().contains(
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

      case "ACKNOWLEDGED":
        return Colors.purple;

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
                hintText: "Search PO Number",
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
                                poId: item["poId"],
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
                                      item["poNumber"],
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
                                      "${item["prNumber"]}   •   ${item["kitchenName"]}   •   ${item["vendorName"]}",
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
                                    "${item["orderDate"]}  -  ${item["expectedDeliveryDate"]}",
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

                                  // Text(
                                  //   "${item["totalItems"] ?? 0} Items",
                                  //   style: TextStyle(
                                  //     color: Colors.grey.shade700,
                                  //     fontSize: 13,
                                  //   ),
                                  // ),
                                  //
                                  // const SizedBox(width: 20),
                                  const Icon(
                                    Icons.currency_rupee,
                                    size: 15,
                                    color: Colors.grey,
                                  ),

                                  Text(
                                    "${item["grandTotal"] ?? 0}",
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
  final int poId;

  const PurchaseRequestDetailsPage({
    Key? key,
    required this.companyId,
    required this.poId,
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
    await Future.wait([loadIngredients(), loadPODetails()]);

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

  Future<void> loadPODetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/${widget.poId}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      prDetails = json["data"]["purchaseOrder"];

      ingredients = List<Map<String, dynamic>>.from(
        json["data"]["items"] ?? [],
      );

      setState(() {});
    }
  }

  Future<void> updateStatus({
    required String endpoint,
    required String successMessage,
  }) async {
    final body = {
      "remarks": "",
      "actionBy": prDetails!["modifiedBy"] ?? "mobile",
    };
    print("========== UPDATE STATUS ==========");
    print("${AppConfig.apiBaseUrl}/api/po/$endpoint/${widget.poId}");
    print(jsonEncode(body));

    final response = await http.put(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/$endpoint/${widget.poId}"),
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

  // Future<void> generatePO() async {
  //   final po = prDetails!;
  //   final status = po["status"];
  //
  //   final body = {
  //     "vendorId": po["vendorId"], // Select vendor if not available
  //     "kitchenId": po["kitchenId"],
  //     "companyId": po["companyId"],
  //     "deliveryAddress": po["deliveryAddress"] ?? "",
  //     "countryCode": "IN",
  //     "currencyCode": "INR",
  //     "orderDate": DateTime.now().toIso8601String().split("T")[0],
  //     "expectedDeliveryDate":
  //         po["requiredByDate"] ??
  //         DateTime.now().toIso8601String().split("T")[0],
  //     "remarks": po["remarks"] ?? "",
  //     "taxType": "EXCLUSIVE",
  //     "taxPercentage": 0,
  //     "shippingAmount": 0,
  //     "otherCharges": 0,
  //     "actionBy": po["modifiedBy"] ?? "mobile",
  //
  //     "items": ingredients.map((item) {
  //       return {
  //         "prIngredientId": item["id"],
  //         "ingredientId": item["ingredientId"],
  //         "ingredientName": ingredientMap[item["ingredientId"]]?["name"] ?? "",
  //         "ingredientTypeId": item["ingredientTypeId"],
  //         "ingredientTypeName": item["ingredientTypeName"],
  //         "uomId": item["uomId"],
  //         "uomName": item["uomName"],
  //         "requiredQty": item["requiredQty"],
  //         "orderedQty": item["requiredQty"],
  //         "unitPrice": item["estimatedUnitPrice"],
  //         "discountPercentage": 0,
  //         "taxType": "EXCLUSIVE",
  //         "taxPercentage": 0,
  //         "taxInclusive": false,
  //         "taxSource": "NONE",
  //         "remarks": "",
  //       };
  //     }).toList(),
  //   };
  //
  //   print("========= GENERATE PO =========");
  //   print(jsonEncode(body));
  //
  //   final response = await http.post(
  //     Uri.parse(
  //       "${AppConfig.apiBaseUrl}/api/po/generate-from-pr/${widget.poId}",
  //     ),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(body),
  //   );
  //
  //   print(response.statusCode);
  //   print(response.body);
  //
  //   if (response.statusCode == 201) {
  //     final json = jsonDecode(response.body);
  //
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(json["status"]["message"])));
  //
  //     Navigator.pop(context, true);
  //   } else {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(response.body)));
  //   }
  // }

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
      amount += ((item["lineTotal"] ?? 0) as num).toDouble();
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
    final po = prDetails!;
    final status = po["status"];

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
                            po["poNumber"],
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
                            po["status"],
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

                    detailRow("Vendor", po["vendorName"] ?? ""),

                    detailRow(
                      "Kitchen",
                      "FPU", // API kitchen name
                    ),

                    // detailRow(
                    //   "Meal",
                    //   "Dinner", // API meal name
                    // ),
                    detailRow("Order Date", formatDate(po["orderDate"])),

                    detailRow(
                      "Expected Delivery",
                      formatDate(po["expectedDeliveryDate"]),
                    ),

                    detailRow("Created By", po["createdBy"]),

                    detailRow(
                      "Created On",
                      po["createdAt"].toString().replaceFirst("T", " "),
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
                      child: summary(ingredients.length.toString(), "Items"),
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
                Expanded(child: buildActionButton(status)),

                const SizedBox(width: 10),

                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    setState(() {
                      showItems = !showItems;
                    });
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showItems
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFFF15F28),
                      size: 20,
                    ),
                  ),
                ),
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
                            "₹${item["lineTotal"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            "Rate ₹${item["unitPrice"]}",
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
                  style: TextStyle(color: Colors.white, fontSize: 14),
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
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        );

      case "APPROVED":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
          onPressed: () {
            updateStatus(
              endpoint: "sendToVendor",
              successMessage: "PO Sent to Vendor",
            );
          },
          child: const Text(
            "Mark Sent to Vendor",
            style: TextStyle(color: Colors.white),
          ),
        );

      case "SENT_TO_VENDOR":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            updateStatus(
              endpoint: "acknowledge",
              successMessage: "Vendor Acknowledged",
            );
          },
          child: const Text(
            "Acknowledge",
            style: TextStyle(color: Colors.white),
          ),
        );

      case "ACKNOWLEDGED":
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GenerateGRNPage(poId: widget.poId),
              ),
            );
          },
          child: const Text(
            "Create GRN",
            style: TextStyle(color: Colors.white),
          ),
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
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/updateDraft/${widget.poId}"),
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

class GenerateGRNPage extends StatefulWidget {
  final int poId;

  const GenerateGRNPage({super.key, required this.poId});

  @override
  State<GenerateGRNPage> createState() => _GenerateGRNPageState();
}

class _GenerateGRNPageState extends State<GenerateGRNPage> {
  Map<String, dynamic>? po;

  List<Map<String, dynamic>> poItems = [];

  List<Map<String, dynamic>> warehouses = [];

  int? warehouseId;

  String? warehouseName;

  DateTime receivedDate = DateTime.now();

  final invoiceNoController = TextEditingController();

  final challanController = TextEditingController();

  final vehicleController = TextEditingController();

  final receivedByController = TextEditingController();

  final inspectedByController = TextEditingController();

  final receivedDateController = TextEditingController();

  final invoiceDateController = TextEditingController();

  final remarksController = TextEditingController();

  DateTime? invoiceDate;

  @override
  void initState() {
    super.initState();

    receivedDateController.text =
        "${receivedDate.year}-${receivedDate.month.toString().padLeft(2, '0')}-${receivedDate.day.toString().padLeft(2, '0')}";

    loadPODetails().then((_) {
      loadWarehouses();
    });
  }

  Future<void> pickReceivedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: receivedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        receivedDate = picked;
        receivedDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> pickManufacturingDate(Map<String, dynamic> item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item["manufacturingDate"] != null
          ? DateTime.parse(item["manufacturingDate"])
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        item["manufacturingDate"] =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> pickExpiryDate(Map<String, dynamic> item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item["expiryDate"] != null
          ? DateTime.parse(item["expiryDate"])
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        item["expiryDate"] =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> pickInvoiceDate() async {
    final DateTime initial = invoiceDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        invoiceDate = picked;
        invoiceDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> loadPODetails() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/${widget.poId}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      po = json["data"]["purchaseOrder"];
      receivedByController.text = po?["createdBy"] ?? "";

      poItems = List<Map<String, dynamic>>.from(json["data"]["items"]);

      for (final item in poItems) {
        item["receivedQty"] = item["receivedQty"];
        item["acceptedQty"] = item["expectedQty"];
        item["orderedQty"] = item["orderedQty"];
        item["remainingQty"] = item["pendingQty"];
        item["rejectedQty"] = 0;
        item["damagedQty"] = 0;
        item["shortQty"] = 0;
        item["batchNumber"] = "";
        item["manufacturingDate"] = null;
        item["expiryDate"] = null;
        item["qcStatus"] = "Pending";
        item["remarks"] = "";
      }

      setState(() {});
    }
  }

  Future<void> loadWarehouses() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/kitchenAllGet/list"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      warehouses = List<Map<String, dynamic>>.from(json["data"]);

      if (po != null) {
        warehouseId = po!["kitchenId"];

        final warehouse = warehouses.firstWhere(
          (e) => e["id"] == warehouseId,
          orElse: () => <String, dynamic>{},
        );

        if (warehouse.isNotEmpty) {
          warehouseName = warehouse["name"];
        }
      }

      setState(() {});
    }
  }

  Future<void> createDraftGRN() async {
    final body = {
      "poId": widget.poId,

      "warehouseId": po?["kitchenId"],

      "warehouseName": warehouseName,

      "receivedDate": receivedDate.toIso8601String().split("T")[0],

      "invoiceNumber": invoiceNoController.text,

      "invoiceDate": invoiceDate == null
          ? null
          : invoiceDate!.toIso8601String().split("T")[0],

      "deliveryChallanNumber": challanController.text,

      "vehicleNumber": vehicleController.text,

      "receivedBy": receivedByController.text,

      "inspectedBy": inspectedByController.text,

      "remarks": remarksController.text,

      "actionBy": "Mobile PO",

      "items": poItems.map((item) {
        return {
          "poItemId": item["poItemId"],

          "expectedQty": item["expectedQty"],

          "acceptedQty": item["acceptedQty"],

          "receivedQty": item["receivedQty"],

          "remainingQty": item["remainingQty"],

          "rejectedQty": item["rejectedQty"],

          "damagedQty": item["damagedQty"],

          "shortQty": item["shortQty"],

          "batchNumber": item["batchNumber"],

          "manufacturingDate": item["manufacturingDate"],

          "expiryDate": item["expiryDate"],

          "qcStatus": item["qcStatus"],

          "remarks": item["remarks"],
        };
      }).toList(),
    };
    for (var item in poItems) {
      print(item);
    }
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/grn/createDraft"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print(jsonEncode(body));
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

  Widget sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF15F28).withOpacity(.12),
            child: Icon(icon, color: const Color(0xFFF15F28), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      labelStyle: const TextStyle(fontSize: 13, color: Colors.black87),

      prefixIcon: Icon(icon, size: 18, color: Colors.grey),

      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),

      filled: true,
      fillColor: Colors.grey.shade50,

      isDense: true,

      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF15F28), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate GRN"),
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
            onPressed: createDraftGRN,
            child: const Text(
              "Create GRN Draft",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(Icons.description_outlined, "GRN Details"),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: warehouseId,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      decoration: fieldDecoration(
                        "Warehouse",
                        Icons.warehouse_outlined,
                      ),
                      items: warehouses.map((warehouse) {
                        return DropdownMenuItem<int>(
                          value: warehouse["id"],
                          child: Text(warehouse["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          warehouseId = value;
                          warehouseName = warehouses.firstWhere(
                            (e) => e["id"] == value,
                          )["name"];
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: receivedDateController,
                      readOnly: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Received Date",
                        Icons.calendar_today,
                      ),
                      onTap: pickReceivedDate,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: invoiceDateController,
                      readOnly: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Invoice Date",
                        Icons.calendar_today,
                      ),
                      onTap: pickInvoiceDate,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: invoiceNoController,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Invoice Number",
                        Icons.receipt_long,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: challanController,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Challan Number",
                        Icons.format_list_numbered_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: vehicleController,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Vehicle Number",
                        Icons.local_shipping,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: receivedByController,
                      readOnly: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration("Received By", Icons.person),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: inspectedByController,
                      style: const TextStyle(fontSize: 13),
                      decoration: fieldDecoration(
                        "Inspected By",
                        Icons.person_3_sharp,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: remarksController,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 3,
                      decoration: fieldDecoration("Remarks", Icons.notes),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            sectionTitle(Icons.shopping_cart_checkout, "PO Items"),

            const SizedBox(height: 10),

            ...poItems.map((item) {
              return Card(
                elevation: 3,
                shadowColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // const CircleAvatar(
                            //   radius: 18,
                            //   backgroundColor: Color(0xFFF15F28),
                            //   child: Icon(Icons.inventory, color: Colors.white),
                            // ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item["ingredientName"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "Ordered Qty : ${item["orderedQty"]}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        initialValue: item["receivedQty"].toString(),
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          "Received Qty",
                          Icons.scale,
                        ),
                        onChanged: (value) {
                          item["receivedQty"] = double.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        initialValue: item["remainingQty"].toString(),
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          "Remaining Qty",
                          Icons.scale,
                        ),
                        onChanged: (value) {
                          item["remainingQty"] = double.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        initialValue: item["acceptedQty"].toString(),
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          "Accepted Qty",
                          Icons.check_circle_outline,
                        ),
                        onChanged: (value) {
                          item["acceptedQty"] = double.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        style: const TextStyle(fontSize: 13),
                        initialValue: item["rejectedQty"].toString(),
                        decoration: fieldDecoration(
                          "Rejected Qty",
                          Icons.cancel_outlined,
                        ),
                        onChanged: (value) {
                          item["rejectedQty"] = double.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        style: const TextStyle(fontSize: 13),
                        initialValue: item["damagedQty"].toString(),
                        decoration: fieldDecoration(
                          "Damaged Qty",
                          Icons.warning_amber,
                        ),
                        onChanged: (value) {
                          item["damagedQty"] = double.tryParse(value) ?? 0;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        style: const TextStyle(fontSize: 13),
                        decoration: fieldDecoration(
                          "Batch Number",
                          Icons.qr_code,
                        ),
                        onChanged: (value) {
                          item["batchNumber"] = value;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: item["manufacturingDate"] ?? "",
                        ),
                        style: const TextStyle(fontSize: 13),
                        decoration: fieldDecoration(
                          "Manufacturing Date",
                          Icons.calendar_month,
                        ),
                        onTap: () => pickManufacturingDate(item),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: item["expiryDate"] ?? "",
                        ),
                        style: const TextStyle(fontSize: 13),
                        decoration: fieldDecoration(
                          "Expiry Date",
                          Icons.event_busy,
                        ),
                        onTap: () => pickExpiryDate(item),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: item["qcStatus"],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        decoration: fieldDecoration(
                          "QC Status",
                          Icons.verified,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Pending",
                            child: Text("Pending"),
                          ),
                          DropdownMenuItem(
                            value: "Passed",
                            child: Text("Passed"),
                          ),
                          DropdownMenuItem(
                            value: "Failed",
                            child: Text("Failed"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            item["qcStatus"] = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        style: const TextStyle(fontSize: 13),
                        decoration: fieldDecoration("Remarks", Icons.notes),
                        onChanged: (value) {
                          item["remarks"] = value;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
