import 'package:flutter/material.dart';

import 'PurchaseRequestCreatePage.dart';
import 'PurchaseRequestGeneratePage.dart';
import 'PurchaseRequestListPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodswing_flutter/config_loader.dart';

class PurchaseRequestPage extends StatefulWidget {
  final String companyId;

  const PurchaseRequestPage({Key? key, required this.companyId})
    : super(key: key);

  @override
  State<PurchaseRequestPage> createState() => _PurchaseRequestPageState();
}

class _PurchaseRequestPageState extends State<PurchaseRequestPage> {
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
      Uri.parse("${AppConfig.apiBaseUrl}/api/pr/dashboard"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      setState(() {
        dashboard = json["data"];
        recentPRs = List<Map<String, dynamic>>.from(json["data"]["recentPRs"]);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  double get todayPRValue {
    double total = 0;

    final today = DateTime.now();

    for (var pr in recentPRs) {
      if (pr["estimatedAmount"] == null) continue;

      final created = DateTime.parse(pr["createdAt"]);

      if (created.year == today.year &&
          created.month == today.month &&
          created.day == today.day) {
        total += (pr["estimatedAmount"] as num).toDouble();
      }
    }

    return total;
  }

  double get monthlyPRValue {
    double total = 0;

    final today = DateTime.now();

    for (var pr in recentPRs) {
      if (pr["estimatedAmount"] == null) continue;

      final created = DateTime.parse(pr["createdAt"]);

      if (created.year == today.year && created.month == today.month) {
        total += (pr["estimatedAmount"] as num).toDouble();
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
          "Purchase Request",
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
            const Text(
              "PR Dashboard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _statCard(
                  "Total PR",
                  "${dashboard["totalPRs"] ?? 0}",
                  Colors.blue,
                ),

                _statCard(
                  "Draft",
                  "${dashboard["draftCount"] ?? 0}",
                  Colors.orange,
                ),

                _statCard(
                  "Approved",
                  "${dashboard["approvedCount"] ?? 0}",
                  Colors.green,
                ),

                _statCard(
                  "Rejected",
                  "${dashboard["rejectedCount"] ?? 0}",
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _valueCard(
                    "Today's PR Value",
                    "₹${todayPRValue.toStringAsFixed(2)}",
                    Colors.deepPurple,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _valueCard(
                    "Monthly PR Value",
                    "₹${monthlyPRValue.toStringAsFixed(2)}",
                    Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Quick Actions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: .9,
              children: [
                _actionButton(Icons.auto_mode, "Generate", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PurchaseRequestGeneratePage(
                        companyId: widget.companyId,
                      ),
                    ),
                  );
                }),

                _actionButton(Icons.add_box, "Create", Colors.green, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PurchaseRequestCreatePage(
                        companyId: widget.companyId,
                      ),
                    ),
                  );
                }),

                _actionButton(Icons.list_alt, "PR List", Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PurchaseRequestListPage(companyId: widget.companyId),
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

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: const [
            //     Text(
            //       "Recent Purchase Requests",
            //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            //     ),
            //
            //     Text(
            //       "View All",
            //       style: TextStyle(
            //         color: Colors.orange,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ],
            // ),
            //
            // const SizedBox(height: 10),
            //
            // ListView.builder(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   itemCount: 5,
            //   itemBuilder: (context, index) {
            //     return Card(
            //       child: ListTile(
            //         leading: CircleAvatar(
            //           backgroundColor: Colors.orange.shade100,
            //           child: const Icon(
            //             Icons.description,
            //             color: Colors.orange,
            //           ),
            //         ),
            //
            //         title: Text("PR-2026000${index + 1}"),
            //
            //         subtitle: const Text("Central Kitchen\n02 Jun 2026"),
            //
            //         isThreeLine: true,
            //
            //         trailing: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             const Text(
            //               "₹45,500",
            //               style: TextStyle(fontWeight: FontWeight.bold),
            //             ),
            //
            //             const SizedBox(height: 4),
            //
            //             Container(
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 8,
            //                 vertical: 3,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: Colors.orange.shade100,
            //                 borderRadius: BorderRadius.circular(20),
            //               ),
            //               child: const Text(
            //                 "Pending",
            //                 style: TextStyle(
            //                   color: Colors.orange,
            //                   fontSize: 11,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     );
            //   },
            // ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(title),
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
