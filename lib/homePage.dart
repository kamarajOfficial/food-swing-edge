// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'config_loader.dart';
//
// class HomePage extends StatefulWidget {
//   final String companyId;
//
//   const HomePage({super.key, required this.companyId});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   List<dynamic> mealTypes = [];
//   List<dynamic> itemTypes = [];
//   List<dynamic> menuItems = [];
//   Map<String, List<dynamic>> groupedMenu = {}; // mealName -> items
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMealsAndMenu();
//     _fetchItems();
//   }
//
//   Future<void> _fetchItems() async {
//     final response = await http.get(
//       Uri.parse('${AppConfig.localBaseUrl}/api/itemAllGet/list'),
//     );
//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       itemTypes = jsonData['data'];
//
//       // Fetch image for each meal using uomId
//       for (var item in itemTypes) {
//         final uomId = item['uomId'];
//         if (uomId != null) {
//           final imageResponse = await http.get(
//             Uri.parse('${AppConfig.localBaseUrl}/api/attachmentDownload/$uomId'),
//           );
//           if (imageResponse.statusCode == 200) {
//             item['imageBytes'] = imageResponse.bodyBytes;
//           }
//         }
//       }
//     } else {
//       print('Failed to fetch item. Status code: ${response.statusCode}');
//     }
//   }
//
//   Future<void> _fetchMealsAndMenu() async {
//     setState(() => _isLoading = true);
//     try {
//       // Fetch meals
//       final mealResponse = await http.get(
//         Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGet/list'),
//       );
//       if (mealResponse.statusCode == 200) {
//         final jsonData = json.decode(mealResponse.body);
//         mealTypes = jsonData['data'];
//
//         // Fetch menu for yesterday
//         final yesterday = DateTime.now().subtract(const Duration(days: 1));
//         final dateStr =
//             "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
//
//         final mealIds = mealTypes.map((m) => m['id'].toString()).join(',');
//         final menuUrl = Uri.parse(
//           '${AppConfig.localBaseUrl}/api/menuPlanningList/$dateStr/$dateStr/${widget.companyId}/$mealIds/1',
//         );
//
//         final menuResponse = await http.get(menuUrl);
//         if (menuResponse.statusCode == 200) {
//           final menuData = json.decode(menuResponse.body);
//           menuItems = menuData['data'] ?? [];
//
//           // Group items by meal type
//           groupedMenu.clear();
//           for (var item in menuItems) {
//             final mealName = item['mealName'] ?? 'Unknown Meal';
//             groupedMenu.putIfAbsent(mealName, () => []).add(item);
//           }
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Weekly Menu')),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : groupedMenu.isEmpty
//               ? const Center(child: Text('No menu available'))
//               : ListView(
//                 padding: const EdgeInsets.all(16),
//                 children:
//                     groupedMenu.entries.map((entry) {
//                       final mealName = entry.key;
//                       final items = entry.value;
//
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Meal type header
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               mealName,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                             height: 260, // total height for image + name
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               itemCount: items.length,
//                               itemBuilder: (context, index) {
//                                 final item = items[index];
//
//                                 // Find item in itemTypes using itemId
//                                 final fetchedItem = itemTypes.firstWhere(
//                                   (i) => i['id'] == item['itemId'],
//                                   orElse: () => null,
//                                 );
//
//                                 final imageBytes =
//                                     fetchedItem != null
//                                         ? fetchedItem['imageBytes']
//                                         : null;
//
//                                 return Container(
//                                   width: 200,
//                                   margin: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       // Image container
//                                       // Image container
//                                       Container(
//                                         padding: const EdgeInsets.all(8),
//                                         child:
//                                             imageBytes != null
//                                                 ? ClipRRect(
//                                                   borderRadius:
//                                                       BorderRadius.circular(40),
//                                                   // Rounded rectangle
//                                                   child: Image.memory(
//                                                     imageBytes,
//                                                     width: 180,
//                                                     height: 180,
//                                                     fit: BoxFit.cover,
//                                                   ),
//                                                 )
//                                                 : ClipRRect(
//                                                   borderRadius:
//                                                       BorderRadius.circular(16),
//                                                   child: Container(
//                                                     width: 180,
//                                                     height: 180,
//                                                     color: Colors.grey.shade200,
//                                                   ),
//                                                 ),
//                                       ),
//
//                                       const SizedBox(height: 6),
//                                       // Wrap Text in Flexible to prevent overflow
//                                       Flexible(
//                                         child: Text(
//                                           item['itemName'] ?? 'Unknown',
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       );
//                     }).toList(),
//               ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
//
// class HomePage extends StatefulWidget {
//   final String companyId;
//
//   const HomePage({super.key, required this.companyId});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage>
//     with SingleTickerProviderStateMixin {
//   late PageController _pageController;
//   int _currentPage = 0;
//
//   final List<String> _images = [
//     'assets/images/home.png',
//     'assets/images/media.jpg',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: 0);
//
//     // Auto-slide every 3 seconds
//     Future.delayed(const Duration(seconds: 3), _autoSlide);
//   }
//
//   void _autoSlide() {
//     if (!mounted) return;
//     _currentPage = (_currentPage + 1) % _images.length;
//     _pageController.animateToPage(
//       _currentPage,
//       duration: const Duration(seconds: 1),
//       curve: Curves.easeInOut,
//     );
//
//     // Repeat
//     Future.delayed(const Duration(seconds: 3), _autoSlide);
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       // appBar: AppBar(
//       //   title: const Text("Home"),
//       //   backgroundColor: Colors.deepOrangeAccent,
//       //   centerTitle: true,
//       // ),
//       body: Column(
//         children: [
//           const SizedBox(height: 100),
//           // Image Slider Box
//           ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: SizedBox(
//               height: 220,
//               child: PageView.builder(
//                 controller: _pageController,
//                 itemCount: _images.length,
//                 itemBuilder: (context, index) {
//                   return Image.asset(
//                     _images[index],
//                     fit: BoxFit.cover,
//                     width: double.infinity,
//                   );
//                 },
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           // Dots Indicator
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               _images.length,
//               (index) => AnimatedContainer(
//                 duration: const Duration(milliseconds: 400),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 width: _currentPage == index ? 12 : 8,
//                 height: _currentPage == index ? 12 : 8,
//                 decoration: BoxDecoration(
//                   color:
//                       _currentPage == index
//                           ? Colors.deepOrangeAccent
//                           : Colors.grey,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
//
// class HomePage extends StatefulWidget {
//   final String companyId;
//
//   const HomePage({super.key, required this.companyId});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: const Text('Home Page'),
//       //   centerTitle: true,
//       // ),
//       body: Center(
//         child: Image.asset(
//           'assets/images/video.gif',
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config_loader.dart';

class HomePage extends StatefulWidget {
  final String companyId;
  final List<dynamic>? loginSessions; // 👈 new field for multiple subCustomers

  const HomePage({super.key, required this.companyId, this.loginSessions});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> dashboardData = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        "count": "2",
        "title": "indent_alerts",
        "image": "assets/images/Indent Alerts.png",
      },
      {
        "count": "4",
        "title": "acknowledge_handover_receipt",
        "image": "assets/images/Acknowledge.png",
      },
      {
        "count": "3",
        "title": "monthly_order_summary",
        "image": "assets/images/Monthly Order.png",
      },
      {
        "count": "5",
        "title": "on_time_delivery_tracking",
        "image": "assets/images/Tracking.png",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Top Banner Image with main.jpg overlay
              Container(
                margin: const EdgeInsets.all(13),
                height: 230,
                clipBehavior: Clip.antiAlias,
                // ensures corners stay rounded
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 🔹 Zoomed Car Image Background
                    Transform.scale(
                      scale: 1.0, // zoom level (1.0 = normal)
                      child: Transform.translate(
                        offset: const Offset(-0, 0),
                        // 👈 moves image 20px to the left
                        child: Image.asset(
                          'assets/images/foodswing.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Dashboard Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () {
                        final titleKey = card["title"];

                        // Disable these cards
                        if (titleKey == "indent_alerts" ||
                            titleKey == "monthly_order_summary" ||
                            titleKey == "on_time_delivery_tracking") {
                          return;
                        }

                        // Only this card should navigate
                        if (titleKey == "acknowledge_handover_receipt") {
                          final subCustomers =
                              widget.loginSessions
                                  ?.map(
                                    (s) => {
                                      'id': s['subCustomerId'],
                                      'name': s['subCustomerName'],
                                    },
                                  )
                                  .toList() ??
                              [];

                          if (subCustomers.length <= 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DeliveryEntryScreen(
                                      subCustomerId:
                                          subCustomers.isNotEmpty
                                              ? subCustomers[0]['id'].toString()
                                              : null,
                                      companyId: widget.companyId,
                                    ),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: Text("select_sub_customers").tr(),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 300,
                                      child: ListView(
                                        children:
                                            subCustomers.map((sc) {
                                              return ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            _,
                                                          ) => DeliveryEntryScreen(
                                                            subCustomerId:
                                                                sc['id']
                                                                    .toString(),
                                                            companyId:
                                                                widget
                                                                    .companyId,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Text(sc['name']),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                            );
                          }
                        }
                      },

                      child: _buildDashboardCard(
                        count: card["count"]!,
                        title: card["title"]!.toString().tr(),
                        imagePath: card["image"]!,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String count,
    required String title,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔹 Prevent overflows
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text section
            Text(
              count,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            // const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
            SizedBox(height: 8),

            Flexible(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryEntryScreen extends StatefulWidget {
  final String? subCustomerId;
  final String companyId;

  const DeliveryEntryScreen({
    Key? key,
    this.subCustomerId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<DeliveryEntryScreen> createState() => _DeliveryEntryScreenState();
}

class _DeliveryEntryScreenState extends State<DeliveryEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> deliveryData = []; // holds API response
  bool _isLoading = true;

  final TextEditingController _cratesController = TextEditingController();
  final TextEditingController _boxesController = TextEditingController();

  final TextEditingController _emptyCratesController = TextEditingController();
  final TextEditingController _emptyBoxesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.subCustomerId != null) {
      _fetchDeliveryData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cratesController.dispose();
    _boxesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final companyId =
          widget.companyId; // replace with actual companyId if dynamic
      final subCustomerId = widget.subCustomerId!;
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/customerForDeliverOffLoad/$companyId/$subCustomerId',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data']);
        setState(() {
          deliveryData = list;

          // ✅ Initialize controllers with default values from API
          final deliveryEntry = deliveryData.firstWhere(
            (e) => e['type'] == 'delivery entry',
            orElse: () => {'crateCount': 0, 'paxCount': 0},
          );
          final emptyVessel = deliveryData.firstWhere(
            (e) => e['type'] == 'empty vessel pickup',
            orElse: () => {'crateCount': 0, 'paxCount': 0},
          );

          // Use separate controllers if needed for each tab
          _cratesController.text = deliveryEntry['crateCount'].toString();
          _boxesController.text = deliveryEntry['paxCount'].toString();

          // You can create separate controllers for empty vessel tab if you want independent editing
          _emptyCratesController.text = emptyVessel['crateCount'].toString();
          _emptyBoxesController.text = emptyVessel['paxCount'].toString();
        });
      } else {
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching delivery data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "location_retail".tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              "current_task".tr(),
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ✅ Geofence status
          Container(
            width: double.infinity,
            color: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                "inside_geo".tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // ✅ Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            tabs: [
              Tab(text: "delivery_entry".tr()),
              Tab(text: "empty_vessel_pickup".tr()),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDeliveryEntryTab(), _buildEmptyVesselTab()],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDeliveryEntry() async {
    final url = Uri.parse(
      '${AppConfig.localBaseUrl}/api/createCustomerForDeliverOffLoad/${widget.companyId}/${widget.subCustomerId}',
    );

    final payload = [
      {
        "crateCount": int.tryParse(_cratesController.text) ?? 0,
        "paxCount": int.tryParse(_boxesController.text) ?? 0,
        "type": "delivery entry",
      },
    ];

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Delivery Entry Saved")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error submitting delivery entry: $e");
    }
  }

  Widget _buildDeliveryEntryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final deliveryEntry = deliveryData.firstWhere(
      (e) => e['type'] == 'delivery entry',
      orElse: () => {'crateCount': 0, 'paxCount': 0},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "assigned_delivery".tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          _buildInfoCard(
            "crates_assigned".tr(),
            deliveryEntry['crateCount'].toString(),
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            "boxes_assigned".tr(),
            deliveryEntry['paxCount'].toString(),
          ),

          const SizedBox(height: 40),
          const Divider(),

          Text(
            "actual_delivery".tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildTextField("actual_crates".tr(), _cratesController),
          const SizedBox(height: 10),
          _buildTextField("actual_boxes".tr(), _boxesController),

          const SizedBox(height: 35),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _submitDeliveryEntry,
              child: Text(
                "submit_delivery".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmptyVesselPickup() async {
    final url = Uri.parse(
      '${AppConfig.localBaseUrl}/api/createCustomerForDeliverOffLoad/${widget.companyId}/${widget.subCustomerId}',
    );

    final payload = [
      {
        "crateCount": int.tryParse(_emptyCratesController.text) ?? 0,
        "paxCount": int.tryParse(_emptyBoxesController.text) ?? 0,
        "type": "empty vessel pickup",
      },
    ];

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Empty Vessel Pickup Saved")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error submitting empty vessel: $e");
    }
  }

  Widget _buildEmptyVesselTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final emptyVessel = deliveryData.firstWhere(
      (e) => e['type'] == 'empty vessel pickup',
      orElse: () => {'crateCount': 0, 'paxCount': 0},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "empty_vessel".tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          _buildInfoCard(
            "expected_crates".tr(),
            emptyVessel['crateCount'].toString(),
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            "expected_boxes".tr(),
            emptyVessel['paxCount'].toString(),
          ),

          const SizedBox(height: 40),
          const Divider(),

          Text(
            "actual_delivery".tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildTextField("actual_empty_crates".tr(), _emptyCratesController),
          const SizedBox(height: 10),
          _buildTextField("actual_empty_boxes".tr(), _emptyBoxesController),

          const SizedBox(height: 35),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _submitEmptyVesselPickup,
              child: Text(
                "submit_empty".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            // hintText: "Enter",
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
