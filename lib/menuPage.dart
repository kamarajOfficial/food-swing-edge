// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'config_loader.dart';
//
// class MenuPage extends StatefulWidget {
//   final String companyId;
//
//   const MenuPage({super.key, required this.companyId});
//
//   @override
//   State<MenuPage> createState() => _MenuPageState();
// }
//
// class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
//   List<dynamic> mealTypes = [];
//   List<dynamic> menuItems = [];
//   bool _isLoading = true;
//   Map<String, List<dynamic>> groupedMenu = {}; // mealName -> items
//
//   final List<Color> mealColors = [
//     Colors.orange.shade100,
//     Colors.green.shade100,
//     Colors.blue.shade100,
//     Colors.purple.shade100,
//     Colors.red.shade100,
//     Colors.yellow.shade100,
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMealsAndMenu();
//   }
//
//   Future<void> _fetchMealsAndMenu() async {
//     setState(() => _isLoading = true);
//
//     try {
//       // 1️⃣ Fetch meals (without blocking on image loading)
//       final mealResponse =
//       await http.get(Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGet/list'));
//
//       if (mealResponse.statusCode == 200) {
//         final jsonData = json.decode(mealResponse.body);
//         mealTypes = jsonData['data'];
//
//         // Get all meal IDs for menu query
//         final mealIds = mealTypes.map((m) => m['id'].toString()).join(',');
//
//         // 2️⃣ Fetch menu data
//         final yesterday = DateTime.now().subtract(const Duration(days: 1));
//         final dateStr =
//             "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
//
//         final menuUrl = Uri.parse(
//           '${AppConfig.localBaseUrl}/api/menuPlanningList/$dateStr/$dateStr/${widget.companyId}/$mealIds/1',
//         );
//
//         final menuResponse = await http.get(menuUrl);
//         if (menuResponse.statusCode == 200) {
//           final menuData = json.decode(menuResponse.body);
//           menuItems = menuData['data'] ?? [];
//
//           // Group items by meal name
//           groupedMenu.clear();
//           for (var item in menuItems) {
//             final mealName = item['mealName'] ?? 'Unknown Meal';
//             groupedMenu.putIfAbsent(mealName, () => []).add(item);
//           }
//
//           // ✅ Show UI immediately
//           setState(() => _isLoading = false);
//
//           // 3️⃣ Load images asynchronously (non-blocking)
//           _loadMealImages();
//           _loadItemImages();
//         } else {
//           throw Exception('Failed to load menu');
//         }
//       } else {
//         throw Exception('Failed to fetch meals');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // Load meal images in background
//   Future<void> _loadMealImages() async {
//     for (var meal in mealTypes) {
//       final uomId = meal['uomId'];
//       if (uomId != null) {
//         http.get(Uri.parse('${AppConfig.localBaseUrl}/api/attachmentDownload/$uomId'))
//             .then((response) {
//           if (response.statusCode == 200) {
//             setState(() {
//               meal['imageBytes'] = response.bodyBytes;
//             });
//           }
//         }).catchError((e) {
//           debugPrint("Failed to load meal image for $uomId: $e");
//         });
//       }
//     }
//   }
//
//   // Load item images in background
//   Future<void> _loadItemImages() async {
//     for (var item in menuItems) {
//       final uomId = item['uomId'];
//       if (uomId != null) {
//         http.get(Uri.parse('${AppConfig.localBaseUrl}/api/attachmentDownload/$uomId'))
//             .then((response) {
//           if (response.statusCode == 200) {
//             setState(() {
//               item['imageBytes'] = response.bodyBytes;
//             });
//           }
//         }).catchError((e) {
//           debugPrint("Failed to load item image for $uomId: $e");
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : groupedMenu.isEmpty
//           ? const Center(child: Text('No menu available for yesterday'))
//           : ListView(
//         padding: const EdgeInsets.all(16),
//         children: groupedMenu.entries.map((entry) {
//           final mealName = entry.key;
//           final items = entry.value;
//
//           final mealImage = mealTypes
//               .firstWhere(
//                 (m) => m['name'] == mealName,
//             orElse: () => null,
//           )?['imageBytes'];
//
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Meal image with overlay name
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Container(
//                     height: 150,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       image: mealImage != null
//                           ? DecorationImage(
//                         image: MemoryImage(mealImage),
//                         fit: BoxFit.cover,
//                       )
//                           : null,
//                       color: mealImage == null
//                           ? Colors.grey.shade300
//                           : null,
//                     ),
//                   ),
//                   Container(
//                     height: 150,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       color: Colors.black.withOpacity(0.3),
//                     ),
//                   ),
//                   Text(
//                     mealName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       shadows: [
//                         Shadow(
//                           blurRadius: 4,
//                           color: Colors.black,
//                           offset: Offset(2, 2),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // Horizontal slider of items
//               SizedBox(
//                 height: 120,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     final item = items[index];
//                     final color =
//                     mealColors[index % mealColors.length];
//
//                     return Container(
//                       width: 200,
//                       margin:
//                       const EdgeInsets.symmetric(horizontal: 6),
//                       child: Card(
//                         color: color,
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             item['imageBytes'] != null
//                                 ? Image.memory(
//                               item['imageBytes'],
//                               width: 60,
//                               height: 60,
//                               fit: BoxFit.cover,
//                             )
//                                 : const Icon(
//                               Icons.fastfood_rounded,
//                               size: 40,
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               item['itemName'] ?? 'Unknown Item',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             Text(
//                               '${item['gram'] ?? '-'} gm',
//                               style: const TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config_loader.dart';

class MenuPage extends StatefulWidget {
  final String companyId;
  final bool isFsCustomer; // 👈 ADD THIS
  final String username;

  const MenuPage({
    super.key,
    required this.companyId,
    this.isFsCustomer = false, // 👈 default
    required this.username
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> mealTypes = [];
  List<dynamic> menuItems = [];
  Map<String, List<dynamic>> groupedMenu = {}; // mealName -> items
  bool _isLoading = false;
  String selectedDay = '';

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();

    // 🔹 Determine current day (e.g., Mon, Tue, ...)
    final now = DateTime.now();
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayName = weekDays[now.weekday - 1];

    // 🔹 Set the default selected day
    selectedDay = todayName;

    // 🔹 Fetch meal types, then menu for current day
    _fetchMealTypes().then((_) {
      _fetchMenuForDay(selectedDay);
    });
  }

  Future<void> _fetchMealTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGetMobile/list'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          mealTypes = jsonData['data'];
        });
      }
    } catch (e) {
      print('Error fetching meals: $e');
    }
  }

  // Fetch menu for a specific day
  Future<void> _fetchMenuForDay(String day) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      selectedDay = day;
      menuItems = [];
      groupedMenu.clear();
    });

    try {
      // Map day name to date
      final today = DateTime.now();
      final weekdayIndex = weekDays.indexOf(day); // 0 = Mon
      final currentWeekday = today.weekday; // 1=Mon..7=Sun
      final difference = weekdayIndex + 1 - currentWeekday;
      final targetDate = today.add(Duration(days: difference));

      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final mealIds = mealTypes.map((m) => m['id'].toString()).join(',');
      final menuResponse = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/menuPlanForMobile/$dateStr/$dateStr/${widget.companyId}/$mealIds/${widget.username}',
        ),
      );

      if (menuResponse.statusCode == 200) {
        final data = json.decode(menuResponse.body);
        menuItems = data['data'] ?? [];

        // Group by meal name
        for (var item in menuItems) {
          final mealName = item['mealName'] ?? 'Unknown Meal';
          groupedMenu.putIfAbsent(mealName, () => []).add(item);

          // Download images asynchronously
          final attachmentId = item['attachmentId'];
          final categoryAttachmentId = item['categoryAttachmentId'];

          int imageId;

          // Priority: attachmentId > categoryAttachmentId
          if (attachmentId != null && attachmentId != 0) {
            imageId = attachmentId;
          } else if (categoryAttachmentId != null &&
              categoryAttachmentId != 0) {
            imageId = categoryAttachmentId;
          } else {
            imageId = 0; // No image available
          }

          if (imageId != 0) {
            unawaited(_downloadItemImage(item, imageId));
          }
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error fetching menu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadItemImage(
    Map<String, dynamic> item,
    int attachmentId, {
    int retries = 2,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        item['imageBytes'] = response.bodyBytes;
        if (mounted) setState(() {});
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (retries > 0) {
        await _downloadItemImage(item, attachmentId, retries: retries - 1);
      } else {
        print('Failed to download image for ${item['itemName']}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("weekly_menu".tr()),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Light watermark background image (zoomed out a bit)
          Center(
            child: Opacity(
              opacity: 0.05, // Light shade for watermark
              child: Transform.scale(
                scale: 1.0,
                // 👈 Zoom out image (0.7 = 70% of its original size)
                child: Image.asset(
                  widget.isFsCustomer
                      ? 'assets/images/watermark.jpg' // 👈 FS Customer
                      : 'assets/images/foodswing.jpg', // 👈 Normal customer
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Column(
            children: [
              // 🔹 Weekly Menu - Day Buttons (Styled like View/Edit Order)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        weekDays.map((day) {
                          final isSelected = day == selectedDay;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                day,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  selectedDay = day;
                                  _fetchMenuForDay(day);
                                });
                              },
                              selectedColor: const Color(0xFFF15F28),
                              backgroundColor: const Color(0xFFF5EDE7),
                              // Light rose bg
                              // shape: RoundedRectangleBorder(
                              //   borderRadius: BorderRadius.circular(18),
                              // ),
                              elevation: 2,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : groupedMenu.isEmpty
                        ? const Center(child: Text('No menu available'))
                        : ListView(
                          padding: const EdgeInsets.all(16),
                          children:
                              groupedMenu.entries.map((entry) {
                                final mealName = entry.key;
                                final items = entry.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        mealName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 260,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          final item = items[index];
                                          final imageBytes = item['imageBytes'];

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                // IMAGE
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child:
                                                      imageBytes != null
                                                          ? Image.memory(
                                                            imageBytes,
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                          )
                                                          : Container(
                                                            width: 80,
                                                            height: 80,
                                                            color: Color(
                                                              0xFFF5EDE7,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                            ),
                                                          ),
                                                ),

                                                const SizedBox(width: 12),

                                                // ITEM NAME
                                                Expanded(
                                                  child: Text(
                                                    item['itemName'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
              ),
            ],
          ),
          // 🔹 Logo at bottom-right corner (larger and lower)
          Positioned(
            bottom: 6,
            right: 30,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Opacity(
                opacity: 0.95,
                child: Transform.scale(
                  scale: 5.5,
                  // make it 2.5x larger without changing width/height
                  child: Image.asset(
                    'assets/images/sauceit.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
