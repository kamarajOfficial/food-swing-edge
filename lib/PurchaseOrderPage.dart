import 'package:flutter/material.dart';

import 'PurchaseRequestCreatePage.dart';
import 'PurchaseRequestGeneratePage.dart';
import 'PurchaseOrderListPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodswing_flutter/config_loader.dart';

class PurchaseOrderPage extends StatefulWidget {
  final String companyId;
  final String username;

  const PurchaseOrderPage({
    Key? key,
    required this.companyId,
    required this.username,
  }) : super(key: key);

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  bool loading = true;

  Map<String, dynamic> dashboard = {};

  List<Map<String, dynamic>> recentPRs = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final response = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/api/po/dashboard"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        dashboard = json["data"] ?? {};
        recentPRs = List<Map<String, dynamic>>.from(
          dashboard["recentPOs"] ?? [],
        );
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  double get todayPOValue {
    double total = 0;

    final today = DateTime.now();

    for (final po in recentPRs) {
      if (po["grandTotal"] == null || po["orderDate"] == null) continue;

      final date = DateTime.parse(po["orderDate"]);

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        total += (po["grandTotal"] as num).toDouble();
      }
    }

    return total;
  }

  double get monthlyPOValue {
    double total = 0;

    final today = DateTime.now();

    for (final po in recentPRs) {
      if (po["grandTotal"] == null || po["orderDate"] == null) continue;

      final date = DateTime.parse(po["orderDate"]);

      if (date.year == today.year &&
          date.month == today.month) {
        total += (po["grandTotal"] as num).toDouble();
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Purchase Order",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white, // Makes back arrow and icons white
        elevation: 0,
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.orange,
      //   child: const Icon(Icons.add),
      //   onPressed: () {
      //     // TODO: Navigate to Create Purchase Request
      //   },
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${widget.username}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Text(
              "Here's your purchase order overview",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: [
                _statCard(
                  "Total PO",
                  "${dashboard["totalPOs"] ?? 0}",
                  Colors.blue,
                  Icons.description_outlined,
                ),

                _statCard(
                  "Draft",
                  "${dashboard["draftCount"] ?? 0}",
                  Colors.orange,
                  Icons.edit_note_outlined,
                ),

                _statCard(
                  "Submitted",
                  "${dashboard["submittedCount"] ?? 0}",
                  Colors.grey,
                  Icons.outbox_outlined,
                ),

                _statCard(
                  "Approved",
                  "${dashboard["approvedCount"] ?? 0}",
                  Colors.green,
                  Icons.verified_outlined,
                ),

                _statCard(
                  "Partially Received",
                  "${dashboard["partiallyReceivedCount"] ?? 0}",
                  Colors.purple,
                  Icons.incomplete_circle,
                ),

                _statCard(
                  "Closed",
                  "${dashboard["closedCount"] ?? 0}",
                  Colors.red,
                  Icons.cancel_outlined,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _valueCard(
                    "Today's PO Value",
                    "₹${todayPOValue.toStringAsFixed(2)}",
                    Colors.deepPurple,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _valueCard(
                    "Monthly PO Value",
                    "₹${monthlyPOValue.toStringAsFixed(2)}",
                    Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Quick Actions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: .9,
              children: [
            //     _actionButton(Icons.add_box, "Create", Colors.green, () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (_) => PurchaseRequestCreatePage(
            //             companyId: widget.companyId,
            //           ),
            //         ),
            //       );
            //     }),

                _actionButton(Icons.list_alt, "PO List", Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PurchaseOrderListPage(companyId: widget.companyId),
                    ),
                  );
                }),

                _actionButton(Icons.report, "Reports", Colors.blue, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Reports feature coming soon"),
                    ),
                  );
                }),

                //   _actionButton(Icons.inventory, "Stock", Colors.purple, () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder:
                //             (_) => PurchaseRequestListPage(companyId: companyId),
                //       ),
                //     );
                //   }),
              ],
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String title,
      String value,
      Color color,
      IconData icon,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(.12),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueCard(String title, String value, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),

            const SizedBox(height: 8),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      IconData icon,
      String text,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
