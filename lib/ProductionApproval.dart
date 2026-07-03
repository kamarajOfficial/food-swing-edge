import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config_loader.dart';

class ProductionApprovalPage extends StatefulWidget {
  final String companyId;

  const ProductionApprovalPage({super.key, required this.companyId});

  @override
  State<ProductionApprovalPage> createState() => _ProductionApprovalPageState();
}

class _ProductionApprovalPageState extends State<ProductionApprovalPage> {
  List<dynamic> productionData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductionPlan();
  }

  Future<void> _fetchProductionPlan() async {
    try {
      setState(() => _loading = true);

      // ---------------------------------------
      // 1️⃣ Fetch all meals
      // ---------------------------------------
      final mealUrl = "${AppConfig.localBaseUrl}/api/mealAllGetMobile/list";
      final mealRes = await http.get(Uri.parse(mealUrl));

      if (mealRes.statusCode != 200) {
        setState(() => _loading = false);
        return;
      }

      final mealJson = json.decode(mealRes.body);
      final meals = mealJson["data"] as List;

      // Extract IDs → [1,2,3]
      final mealIds = meals.map((m) => m["id"]).toList();

      // Convert to "1,2,3"
      final mealIdString = mealIds.join(",");

      // print("✅ Meal IDs: $mealIdString");

      final tmrw = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          "${tmrw.year}-${tmrw.month.toString().padLeft(2, '0')}-${tmrw.day.toString().padLeft(2, '0')}";

      // final today = DateTime(2025, 09, 09); // your example date
      // final dateStr =
      //     "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final url =
          "${AppConfig.localBaseUrl}/api/indent/companyWiseProductionPlan/"
          "$dateStr/$dateStr/$mealIdString/${widget.companyId}";

      // print("🔗 API URL: $url");

      final response = await http.get(Uri.parse(url));

      // print("📥 Response (${response.statusCode}): ${response.body}");

      // ---------------------------------------
      // 4️⃣ Save data
      // ---------------------------------------
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          productionData = jsonData["data"];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() => _loading = false);
    }
  }

  String _tomorrowDate() {
    final tmrw = DateTime.now().add(const Duration(days: 1));
    return "${tmrw.year}-${tmrw.month.toString().padLeft(2, '0')}-${tmrw.day.toString().padLeft(2, '0')}";
    //  final today = DateTime(2025, 09, 09); // your example date
    // return
    //      "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("production_approval").tr(),

            // 👉 Tomorrow Date (Top-Right Corner)
            Text(
              _tomorrowDate(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Light watermark background image
          Center(
            child: Opacity(
              opacity: 0.05, // Light shade
              child: Transform.scale(
                scale: 1.0, // adjust zoom here
                child: Image.asset(
                  'assets/images/watermark.jpg',
                  fit: BoxFit.contain, // Keep full image visible
                ),
              ),
            ),
          ),
          productionData.isEmpty
              ? const Center(child: Text("No data found"))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: productionData.length,
                itemBuilder: (context, index) {
                  final meal = productionData[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "${meal['mealName']} - ${meal['items'][0]['mealCount']} ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: "(${meal['kitchenName']})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14, // smaller text
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ⭐ STATUS LOGIC HANDLER
                        _buildStatusButtons(meal['status'], meal),

                        const SizedBox(height: 18),

                        // 🔶 TABLE HEADER
                        Row(
                          children: const [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Item",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Qty",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),

                        const Divider(),

                        // 🔶 TABLE ROWS
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: meal["items"]?.length ?? 0,
                          itemBuilder: (ctx, i) {
                            final item = meal["items"][i];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "• ${item['itemName']}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['quantity'].toString(),
                                      style: const TextStyle(fontSize: 15),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  // 🔶 STATUS LOGIC (Approve/Reject/Buttons)
  Widget _buildStatusButtons(int status, dynamic meal) {
    if (status == 1) {
      return const Center(
        child: Text(
          "Approved",
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (status == 2) {
      return const Center(
        child: Text(
          "Rejected",
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Status 0 → show buttons
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              submitApproval(
                id: meal['id'], // 👈 ADD THIS
                mealId: meal['mealId'],
                kitchenId: meal['kitchenId'],
                status: 1,
                remarks: "",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text("Approve", style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _showRemarksDialog(meal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text("Reject", style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Future<void> submitApproval({
    int? id, // 👈 nullable
    required int mealId,
    required int kitchenId,
    required int status,
    String remarks = "",
  }) async {

    // 🔁 Decide API based on id
    final bool isUpdate = id != null && id > 0;

    final String url = isUpdate
        ? "${AppConfig.localBaseUrl}/api/updateGrammageMenuCheck/$id"
        : "${AppConfig.localBaseUrl}/api/createGrammageMenuCheck";

    final payload = {
      "companyId": int.parse(widget.companyId),
      "mealId": mealId,
      "orderDate": _tomorrowDate(),
      "kitchenId": kitchenId,
      "remarks": remarks,
      "status": status,
    };

    print("📤 ${isUpdate ? 'UPDATE' : 'CREATE'} Payload: $payload");

    final http.Response res = isUpdate
        ? await http.put( // 👈 UPDATE uses PUT
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    )
        : await http.post( // 👈 CREATE uses POST
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("📥 Response ${res.statusCode}: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate ? "Updated Successfully!" : "Created Successfully!",
          ),
        ),
      );

      _fetchProductionPlan(); // 🔄 Refresh UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${res.body}")),
      );
    }
  }

  void _showRemarksDialog(dynamic meal) {
    TextEditingController remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Remarks"),
          content: TextField(
            controller: remarkCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Write reason for rejection...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () {
                Navigator.pop(context);
                submitApproval(
                  id: meal['id'], // 👈 ADD THIS
                  mealId: meal['mealId'],
                  kitchenId: meal['kitchenId'],
                  status: 2,
                  remarks: remarkCtrl.text.trim(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
