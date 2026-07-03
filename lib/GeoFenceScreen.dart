import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config_loader.dart';

class GeoFenceScreen extends StatefulWidget {
  final List<int> companyIds;
  final String driverId;
  final List<int> subCustomerIds;
  final String vehicleId;

  const GeoFenceScreen({
    super.key,
    required this.companyIds,
    required this.driverId,
    required this.subCustomerIds,
    required this.vehicleId,
  });

  @override
  State<GeoFenceScreen> createState() => _GeoFenceScreenState();
}

class _GeoFenceScreenState extends State<GeoFenceScreen> {
  bool isInsideGeofence = false;

  List<Map<String, dynamic>> deliveryEntryRows = [];
  List<Map<String, dynamic>> emptyVesselRows = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryData();
  }

  Future<void> _fetchDeliveryData() async {
    try {
      final ids = widget.subCustomerIds.join(',');
      final companyIds = widget.companyIds.join(',');
      print('vehicleId, ${widget.companyIds}');
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/driverForDeliverOffLoad/$companyIds/$ids/${widget.driverId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List<dynamic>;

        final deliveryEntry = data.firstWhere(
          (e) => e['type'] == 'delivery entry',
          orElse: () => null,
        );
        final emptyVessel = data.firstWhere(
          (e) => e['type'] == 'empty vessel pickup',
          orElse: () => null,
        );

        if (deliveryEntry != null) {
          deliveryEntryRows = [
            {
              "item": "crates".tr(),
              "assigned": deliveryEntry['crateCount'],
              "controller": TextEditingController(
                text: deliveryEntry['crateCount'].toString(),
              ),
            },
            {
              "item": "boxes".tr(),
              "assigned": deliveryEntry['paxCount'],
              "controller": TextEditingController(
                text: deliveryEntry['paxCount'].toString(),
              ),
            },
          ];
        }

        if (emptyVessel != null) {
          emptyVesselRows = [
            {
              "item": "empty_crates".tr(),
              "assigned": emptyVessel['crateCount'],
              "controller": TextEditingController(
                text: emptyVessel['crateCount'].toString(),
              ),
            },
            {
              "item": "empty_boxes".tr(),
              "assigned": emptyVessel['paxCount'],
              "controller": TextEditingController(
                text: emptyVessel['paxCount'].toString(),
              ),
            },
          ];
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching delivery data: $e');
    }
  }

  bool _validateInputs() {
    final allRows = [...deliveryEntryRows, ...emptyVesselRows];

    for (var row in allRows) {
      final assigned = row['assigned'] as int;
      final entered = int.tryParse(row['controller'].text) ?? 0;

      if (entered < assigned) {
        _showAlertDialog(context, row['item'], assigned, entered);
        return false;
      }
    }
    return true;
  }

  Future<void> _submitStopActions() async {
    final ids = widget.subCustomerIds.join(",");
    final companyIds = widget.companyIds.join(',');

    final url = Uri.parse(
      "${AppConfig.localBaseUrl}/api/createDriverForDeliverOffLoad/$companyIds/$ids/${widget.driverId}/${widget.vehicleId}",
    );

    final payload = [
      {
        "crateCount":
            int.tryParse(deliveryEntryRows[0]["controller"].text) ?? 0,
        "paxCount": int.tryParse(deliveryEntryRows[1]["controller"].text) ?? 0,
        "type": "delivery entry",
      },
      {
        "crateCount": int.tryParse(emptyVesselRows[0]["controller"].text) ?? 0,
        "paxCount": int.tryParse(emptyVesselRows[1]["controller"].text) ?? 0,
        "type": "empty vessel pickup",
      },
    ];

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final jsonResponse = jsonDecode(response.body);

      // 🔥 Check API status code from response body
      if (jsonResponse["status"]["code"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stop actions submitted successfully!")),
        );
      } else {
        // 🔥 Show server message from API
        final errorMessage =
            jsonResponse["status"]["message"] ?? "Unknown error";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submit Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "simulate".tr(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isInsideGeofence = !isInsideGeofence;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isInsideGeofence ? Colors.green : const Color(0xFFF15F28),
              ),
              child: Text(
                isInsideGeofence ? "exit_geo".tr() : "enter_geo".tr(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildEditableSection(
                      title: "offload_delivery_entry".tr(),
                      columns: [
                        "item".tr(),
                        "assigned".tr(),
                        "actual_delivered".tr(),
                      ],
                      rows: deliveryEntryRows,
                      context: context,
                    ),

                    _buildEditableSection(
                      title: "empty".tr(),
                      columns: [
                        "item".tr(),
                        "expected".tr(),
                        "actual_collected".tr(),
                      ],
                      rows: emptyVesselRows,
                      context: context,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isInsideGeofence
                                ? () {
                                  if (_validateInputs()) {
                                    _submitStopActions();
                                  }
                                }
                                : null,
                        child: Text(
                          isInsideGeofence
                              ? 'submit_stop_actions'.tr()
                              : 'submit_stop_actions_geo_locked'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndSubmit(BuildContext context) {
    final allRows = [...deliveryEntryRows, ...emptyVesselRows];

    for (var row in allRows) {
      final assigned = row['assigned'] as int;
      final entered = int.tryParse(row['controller'].text) ?? 0;

      if (entered < assigned) {
        _showAlertDialog(context, row['item'], assigned, entered);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stop actions submitted successfully!')),
    );
  }

  void _showAlertDialog(
    BuildContext context,
    String item,
    int assigned,
    int entered,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text(
              'Alarm Red Alert!',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              "$item entered quantity ($entered) is less than assigned ($assigned).",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
    required BuildContext context,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children:
                      columns
                          .map(
                            (col) => Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                col,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                ),
                ...rows.map((row) {
                  final controller = row['controller'] as TextEditingController;
                  final assigned = row['assigned'] as int;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(row['item'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          assigned.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class GeoFenceScreen extends StatefulWidget {
//   final String companyId;
//
//   const GeoFenceScreen({super.key, required this.companyId});
//
//   @override
//   State<GeoFenceScreen> createState() => _GeoFenceScreenState();
// }
// class _GeoFenceScreenState extends State<GeoFenceScreen> {
//   bool isInsideGeofence = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F5F9),
//       appBar: AppBar(
//         title: const Text('Simulate Geo-Trigger'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             /// 🔘 Enter / Exit Geofence Button
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   isInsideGeofence = !isInsideGeofence;
//                 });
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                 isInsideGeofence ? Colors.green : Colors.redAccent,
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10)),
//               ),
//               child: Text(
//                 isInsideGeofence ? 'Exit Geofence' : 'Enter Geofence',
//                 style:
//                 const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             /// 🔹 Stop Details Card
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.2),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   )
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Container(
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF1849C6),
//                       borderRadius:
//                       BorderRadius.vertical(top: Radius.circular(12)),
//                     ),
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                     child: Row(
//                       children: [
//                         const Text(
//                           "Stop #4567",
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18),
//                         ),
//                         const SizedBox(width: 8),
//                         const Icon(Icons.location_on,
//                             color: Colors.redAccent, size: 18),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             isInsideGeofence
//                                 ? "Inside 75m Radius"
//                                 : "Outside Geofence (>75m)",
//                             style: TextStyle(
//                               color:
//                               isInsideGeofence ? Colors.greenAccent : Colors
//                                   .white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "The Corner Store, 123 Main St",
//                           style: TextStyle(
//                               color: Colors.black87,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500),
//                         ),
//                         const SizedBox(height: 12),
//
//                         /// 1️⃣ Off-load Delivery Entry
//                         _buildSection(
//                           title: "1. Off-load Delivery Entry",
//                           columns: const ["Item", "Assigned", "Actual Delivered"],
//                           rows: const [
//                             ["Crates", "15", "17"],
//                             ["Boxes", "40", "40"],
//                           ],
//                         ),
//
//                         const SizedBox(height: 16),
//
//                         /// 2️⃣ Empty Vessel Pickup
//                         _buildSection(
//                           title: "2. Empty Vessel Pickup",
//                           columns: const ["Item", "Expected", "Actual Collected"],
//                           rows: const [
//                             ["Empty Vessels", "10", "10"],
//                           ],
//                         ),
//
//                         const SizedBox(height: 16),
//
//                         /// 🔘 Submit Button
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed:
//                             isInsideGeofence ? () {} : null, // disable outside
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: isInsideGeofence
//                                   ? const Color(0xFF1849C6)
//                                   : const Color(0xFFCBD3F5),
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 14, horizontal: 20),
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8)),
//                             ),
//                             child: Text(
//                               isInsideGeofence
//                                   ? 'Submit Stop Actions'
//                                   : 'Submit Stop Actions (Geo-Locked)',
//                               style: TextStyle(
//                                 color: isInsideGeofence
//                                     ? Colors.white
//                                     : Colors.black54,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(height: 6),
//                         Center(
//                           child: Text(
//                             isInsideGeofence
//                                 ? "Ready to submit."
//                                 : "Submission is enabled only inside the geofence.",
//                             style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.black54,
//                                 fontStyle: FontStyle.italic),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSection({
//     required String title,
//     required List<String> columns,
//     required List<List<String>> rows,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.white,
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 3,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(
//                   fontSize: 15,
//                   color: Color(0xFF1849C6),
//                   fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//
//           /// Table Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: columns
//                 .map((col) => Expanded(
//                 child: Text(
//                   col,
//                   style: const TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey,
//                       fontWeight: FontWeight.w600),
//                 )))
//                 .toList(),
//           ),
//           const SizedBox(height: 8),
//
//           /// Table Rows
//           ...rows.map((row) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                       child: Text(row[0],
//                           style: const TextStyle(fontWeight: FontWeight.w500))),
//                   Expanded(
//                       child: Text(row[1],
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold, fontSize: 15))),
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 6, horizontal: 10),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade400),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Center(
//                         child: Text(
//                           row[2],
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList()
//         ],
//       ),
//     );
//   }
// }
