import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config_loader.dart';
import 'package:intl/intl.dart'; // <-- Add this import at the top

// class OrderConfirmedPage extends StatelessWidget {
//   final String username;
//   final String companyId;
//   final String companyName;
//   final List<String> roles;
//
//   const OrderConfirmedPage({
//     super.key,
//     required this.username,
//     required this.companyId,
//     required this.companyName,
//     required this.roles,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.check_circle_outline, color: Colors.green, size: 120),
//               const SizedBox(height: 20),
//               const Text(
//                 'Order Placed',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//
//               const SizedBox(height: 50),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (context) => MainTabPage(
//                             username: username,
//                             companyId: companyId,
//                             companyName: companyName,
//                             roles: roles,
//                           ),
//                     ),
//                     // replace with your homepage widget
//                     (route) => false, // removes all previous routes
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF000080),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 40,
//                     vertical: 14,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Back to Home',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class OrdersPage extends StatefulWidget {
  final String username;
  final String companyId;
  final String companyName;
  final List<dynamic>? loginSessions; // 👈 new field for multiple subCustomers

  const OrdersPage({
    super.key,
    required this.username,
    required this.companyId,
    required this.companyName,
    this.loginSessions,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final PageController _pageController = PageController();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<dynamic> feedbackMeals = [];
  List<dynamic> mealTypes = [];
  List<dynamic> itemTypes = [];
  bool _isLoading = true;
  List<TextEditingController> _subCustomerControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchSubCustomers();
  }

  List<dynamic> _subCustomersList = [];

  Future<void> _fetchSubCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/subCustomerMasterAllGetMobile/list/${widget.companyId}',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final allSubs = jsonData['data'] ?? [];

        // ✅ Extract all subCustomerIds from loginSessions
        final loginSessionSubIds =
            widget.loginSessions
                ?.map((e) => e['subCustomerId'].toString())
                .toList() ??
            [];

        // ✅ Filter only the sub-customers from loginSessions
        if (loginSessionSubIds.isNotEmpty) {
          _subCustomersList =
              allSubs
                  .where(
                    (sub) => loginSessionSubIds.contains(sub['id'].toString()),
                  )
                  .toList();
        } else {
          // Fallback: show all if no login sessions
          _subCustomersList = allSubs;
        }

        // ✅ Initialize controllers for each sub-customer
        _subCustomerControllers =
            _subCustomersList
                .map((sub) => TextEditingController(text: '0'))
                .toList();

        setState(() {});
      } else {
        print("Failed to fetch sub-customers: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sub-customers: $e");
    }
  }

  Future<void> _loadData() async {
    try {
      // 1️⃣ Fetch meals/items without images
      await Future.wait([
        _fetchMeals(fetchImages: false),
        _fetchItems(fetchImages: false),
      ]);

      // 2️⃣ Load feedback
      // await _fetchFeedbackData();

      // 3️⃣ Show UI immediately
      setState(() => _isLoading = false);

      // 4️⃣ Download images in the background (one by one)
      _fetchMealImages();
      // _fetchItemImages();
    } catch (e) {
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _fetchMealImages() async {
    for (var meal in mealTypes) {
      final attachmentId = meal['attachmentId'];
      if (attachmentId != null) {
        try {
          final imageResponse = await http.get(
            Uri.parse(
              '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
            ),
          );
          if (imageResponse.statusCode == 200) {
            if (!mounted) return;
            setState(() {
              meal['imageBytes'] = imageResponse.bodyBytes;
            });
          }
        } catch (e) {
          print("⚠️ Failed to load meal image for $attachmentId: $e");
        }
      }
    }
  }

  void _fetchItemImages() async {
    for (var item in itemTypes) {
      final uomId = item['uomId'];
      if (uomId != null) {
        try {
          final imageResponse = await http.get(
            Uri.parse(
              '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$uomId',
            ),
          );
          if (imageResponse.statusCode == 200) {
            if (!mounted) return;
            setState(() {
              item['imageBytes'] = imageResponse.bodyBytes;
            });
          }
        } catch (e) {
          print("⚠️ Failed to load item image for $uomId: $e");
        }
      }
    }
  }

  Future<void> _fetchMeals({bool fetchImages = true}) async {
    try {
      // 1️⃣ Get company-specific meals
      final companyResponse = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/companyWithMealGetMobile/${widget.companyId}',
        ),
      );

      if (companyResponse.statusCode != 200) {
        print('❌ Failed to fetch company meals.');
        return;
      }

      final companyJson = json.decode(companyResponse.body);
      final List<dynamic> companyMeals = companyJson['data'] ?? [];

      // 2️⃣ Get all meals (for mapping mealId → attachment uomId)
      final mealResponse = await http.get(
        Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGetMobile/list'),
      );

      if (mealResponse.statusCode != 200) {
        print('❌ Failed to fetch all meals.');
        return;
      }

      final mealJson = json.decode(mealResponse.body);
      final List<dynamic> allMeals = mealJson['data'] ?? [];

      // 3️⃣ Merge both results based on mealId (company.id == allMeals.id)
      for (var meal in companyMeals) {
        final matchingMeal = allMeals.firstWhere(
          (m) => m['id'] == meal['id'],
          orElse: () => {},
        );

        if (matchingMeal.isNotEmpty && matchingMeal['uomId'] != null) {
          // Attach the uomId (which is actually attachment ID)
          meal['attachmentId'] = matchingMeal['uomId'];
        }
      }

      // 4️⃣ Save merged list
      setState(() {
        mealTypes = companyMeals;
      });

      // 5️⃣ Optionally load images for each attachmentId
      if (fetchImages) {
        await Future.wait(
          mealTypes.map((meal) async {
            final attachmentId = meal['attachmentId'];
            if (attachmentId != null) {
              try {
                final imageResponse = await http.get(
                  Uri.parse(
                    '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
                  ),
                );
                if (imageResponse.statusCode == 200) {
                  setState(() {
                    meal['imageBytes'] = imageResponse.bodyBytes;
                  });
                }
              } catch (e) {
                print("⚠️ Failed to load meal image for $attachmentId: $e");
              }
            }
          }),
        );
      }

      print("✅ Meals loaded successfully for company ${widget.companyId}");
    } catch (e) {
      print("⚠️ Error fetching meals: $e");
    }
  }

  Future<void> _fetchItems({bool fetchImages = true}) async {
    final response = await http.get(
      Uri.parse('${AppConfig.localBaseUrl}/api/itemAllGetMobile/list'),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      itemTypes = jsonData['data'];

      if (fetchImages) {
        Future.wait(
          itemTypes.map((item) async {
            final uomId = item['uomId'];
            if (uomId != null) {
              try {
                final imageResponse = await http.get(
                  Uri.parse(
                    '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$uomId',
                  ),
                );

                if (imageResponse.statusCode == 200) {
                  setState(() {
                    item['imageBytes'] = imageResponse.bodyBytes;
                  });
                }
              } catch (e) {
                print("Failed to load item image for $uomId: $e");
              }
            }
          }),
        );
      }
    } else {
      print('Failed to fetch items. Status code: ${response.statusCode}');
    }
  }

  Future<void> _fetchFeedbackData() async {
    if (mealTypes.isEmpty) return; // Ensure meals are fetched first

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    // Extract meal IDs dynamically
    final mealIds = mealTypes.map((meal) => meal['id'].toString()).join(',');
    final response = await http.get(
      Uri.parse(
        '${AppConfig.localBaseUrl}/api/indent/companyWiseProductionPlan/$dateStr/$dateStr/$mealIds/45/${widget.companyId}',
      ),
    );

    try {
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          feedbackMeals = jsonData['data'];
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load feedback data");
      }
    } catch (e) {
      print("Error loading feedback: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Widget _buildDateField(DateTime? date, String placeholder) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date == null
                ? placeholder
                : '${date.day}-${date.month}-${date.year}',
            style: const TextStyle(fontSize: 15),
          ),
          const Icon(Icons.calendar_today, color: Color(0xFFF15F28)),
        ],
      ),
    );
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _nextPage() {
    if (_pageController.page! < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final previousDate = DateTime.now().subtract(const Duration(days: 1));
    // final previousDateStr =
    //     "${previousDate.day}-${previousDate.month}-${previousDate.year}";
    final previousDateStr = DateFormat(
      'd MMM yyyy',
    ).format(previousDate); // ✅ 18 Oct 2025 format

    // Group meals by type
    final Map<String, List<dynamic>> mealsByType = {};
    for (var meal in feedbackMeals) {
      final type = meal['mealType'] ?? '';
      if (!mealsByType.containsKey(type)) mealsByType[type] = [];
      mealsByType[type]!.add(meal);
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                  'assets/images/foodswing.jpg',
                  fit: BoxFit.contain, // keeps full image visible
                ),
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: [
              // Page 1: Feedback
              // Padding(
              //   padding: const EdgeInsets.all(20),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       // Header Row with back arrow and Feedback title
              //       Row(
              //         children: [
              //           const SizedBox(width: 105),
              //           // space between icon and text
              //           const Text(
              //             'Feedback',
              //             style: TextStyle(
              //               fontSize: 24,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //       Center(
              //         child: Text(
              //           "$previousDateStr",
              //           style: TextStyle(
              //             fontSize: 14,
              //             color: Colors.black45,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //       Expanded(
              //         child:
              //             feedbackMeals.isEmpty
              //                 ? const Center(
              //                   child: Text(
              //                     "No feedbacks available for yesterday",
              //                   ),
              //                 )
              //                 : ListView(
              //                   children:
              //                       mealsByType.entries.map((entry) {
              //                         final mealType = entry.key;
              //                         final meals = entry.value;
              //
              //                         return Column(
              //                           crossAxisAlignment:
              //                               CrossAxisAlignment.start,
              //                           children: [
              //                             Text(
              //                               mealType,
              //                               style: const TextStyle(
              //                                 fontSize: 16,
              //                                 fontWeight: FontWeight.bold,
              //                                 color: Colors.deepOrangeAccent,
              //                               ),
              //                             ),
              //                             const SizedBox(height: 5),
              //                             ...meals.map((meal) {
              //                               return Padding(
              //                                 padding:
              //                                     const EdgeInsets.symmetric(
              //                                       vertical: 8,
              //                                     ),
              //                                 child: Column(
              //                                   crossAxisAlignment:
              //                                       CrossAxisAlignment.start,
              //                                   children: [
              //                                     Text(
              //                                       meal['mealName'] ??
              //                                           "Unknown",
              //                                       style: const TextStyle(
              //                                         fontSize: 25,
              //                                         fontWeight:
              //                                             FontWeight.bold,
              //                                       ),
              //                                     ),
              //                                     const SizedBox(height: 5),
              //                                     if (meal['items'] != null)
              //                                       ...meal['items'].map<
              //                                         Widget
              //                                       >((item) {
              //                                         // Find item in itemTypes by id
              //                                         final fetchedItem =
              //                                             itemTypes.firstWhere(
              //                                               (it) =>
              //                                                   it['id'] ==
              //                                                   item['itemId'],
              //                                               orElse: () => {},
              //                                             );
              //
              //                                         final itemImageBytes =
              //                                             fetchedItem['imageBytes'];
              //
              //                                         return Padding(
              //                                           padding:
              //                                               const EdgeInsets.symmetric(
              //                                                 vertical: 10,
              //                                               ),
              //                                           child: Row(
              //                                             children: [
              //                                               // Display image if available, else fallback container
              //                                               itemImageBytes !=
              //                                                       null
              //                                                   ? ClipRRect(
              //                                                     borderRadius:
              //                                                         BorderRadius.circular(
              //                                                           15,
              //                                                         ),
              //                                                     child: Image.memory(
              //                                                       itemImageBytes,
              //                                                       width: 80,
              //                                                       height: 80,
              //                                                       fit:
              //                                                           BoxFit
              //                                                               .cover,
              //                                                     ),
              //                                                   )
              //                                                   : Container(
              //                                                     width: 40,
              //                                                     height: 40,
              //                                                     decoration: BoxDecoration(
              //                                                       color:
              //                                                           Colors
              //                                                               .grey[300],
              //                                                       borderRadius:
              //                                                           BorderRadius.circular(
              //                                                             8,
              //                                                           ),
              //                                                     ),
              //                                                     child: const Icon(
              //                                                       Icons
              //                                                           .fastfood,
              //                                                       color:
              //                                                           Colors
              //                                                               .grey,
              //                                                     ),
              //                                                   ),
              //                                               const SizedBox(
              //                                                 width: 10,
              //                                               ),
              //                                               Expanded(
              //                                                 child: Text(
              //                                                   item['itemName'] ??
              //                                                       "Unknown",
              //                                                 ),
              //                                               ),
              //                                               // Star rating row
              //                                               Row(
              //                                                 children: List.generate(5, (
              //                                                   i,
              //                                                 ) {
              //                                                   return GestureDetector(
              //                                                     onTap: () {
              //                                                       setState(() {
              //                                                         item['rating'] =
              //                                                             i + 1;
              //                                                       });
              //                                                     },
              //                                                     child: Icon(
              //                                                       Icons.star,
              //                                                       // <-- IconData goes here
              //                                                       color:
              //                                                           (item['rating'] ??
              //                                                                       0) >
              //                                                                   i
              //                                                               ? Colors.deepOrangeAccent
              //                                                               : Colors.grey,
              //                                                       size: 22,
              //                                                     ),
              //                                                   );
              //                                                 }),
              //                                               ),
              //                                             ],
              //                                           ),
              //                                         );
              //                                       }).toList(),
              //                                   ],
              //                                 ),
              //                               );
              //                             }).toList(),
              //                           ],
              //                         );
              //                       }).toList(),
              //                 ),
              //       ),
              //
              //       SizedBox(height: 20), // add space above button
              //       Center(
              //         child: Padding(
              //           padding: const EdgeInsets.only(bottom: 20),
              //           // moves button up from bottom
              //           child: ElevatedButton(
              //             onPressed: _nextPage,
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor: const Color(0xFFF15F28),
              //               padding: const EdgeInsets.symmetric(
              //                 horizontal: 20,
              //                 vertical: 14,
              //               ),
              //               shape: RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(10),
              //               ),
              //               elevation: 4, // optional subtle shadow
              //             ),
              //             child: const Text(
              //               'Proceed to place a new order',
              //               style: TextStyle(
              //                 color: Colors.white,
              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //       SizedBox(height: 10), // optional space below
              //     ],
              //   ),
              // ),

              // Padding(
              //   padding: const EdgeInsets.all(20),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       // Header Row with back arrow and Feedback title
              //       Row(
              //         children: [
              //           const SizedBox(width: 105),
              //           // space between icon and text
              //           const Text(
              //             'Feedback',
              //             style: TextStyle(
              //               fontSize: 24,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              // Page 2: Delivery Date
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔙 Back button + Title
                    Row(
                      children: [
                        // IconButton(
                        //   icon: const Icon(Icons.arrow_back),
                        //   onPressed: () {
                        //     if (_pageController.page! > 0) {
                        //       _pageController.previousPage(
                        //         duration: const Duration(milliseconds: 400),
                        //         curve: Curves.easeInOut,
                        //       );
                        //     } else {
                        //       Navigator.pop(context);
                        //     }
                        //   },
                        // ),
                        const SizedBox(width: 40),
                        // space between icon and text
                        Text(
                          "delivery_date".tr(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            // ),
                            // ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // 🔹 From Date
                    Text(
                      "from_date".tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFromDate,
                      child: _buildDateField(_fromDate, "select_date".tr()),
                    ),

                    const SizedBox(height: 24),

                    // 🔹 To Date
                    Text(
                      "to_date".tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickToDate,
                      child: _buildDateField(_toDate, "select_date".tr()),
                    ),

                    const SizedBox(height: 170),

                    // 🔸 Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_fromDate == null || _toDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("please".tr()),
                                backgroundColor: Color(0xFFF15F28),
                              ),
                            );
                            return;
                          }

                          _nextPage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF15F28),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "submit".tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page 3: Place Order
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Row for back arrow + centered title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (_pageController.page! > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "place_an_order".tr(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    // Date range display
                    Text(
                      _fromDate != null && _toDate != null
                          ? '${DateFormat("d MMM yyyy").format(_fromDate!)}  -  ${DateFormat("d MMM yyyy").format(_toDate!)}'
                          : 'Select Date Range',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    // Meal List (scrollable)
                    Expanded(
                      child: ListView.builder(
                        itemCount: mealTypes.length,
                        itemBuilder: (context, index) {
                          final meal = mealTypes[index];
                          final imageBytes = meal['imageBytes'];
                          final isExpanded = meal['isExpanded'] ?? false;
                          final subCustomers = meal['subCustomers'] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Meal Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    meal['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: const Color(0xFFF15F28),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        meal['isExpanded'] = !isExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 🔸 Meal Image + Count Field (READ-ONLY total)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child:
                                        imageBytes != null
                                            ? Image.memory(
                                              imageBytes,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              height: 150,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: SizedBox(
                                      width: 80,
                                      height: 40,
                                      child: TextField(
                                        controller: TextEditingController(
                                          text:
                                              (meal['mealCount'] ?? 0)
                                                  .toString(),
                                        ),
                                        readOnly: true,
                                        // 🔒 makes it uneditable
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Count',
                                          labelStyle: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          fillColor: Colors.white.withOpacity(
                                            0.9,
                                          ),
                                          filled: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 🔽 Sub-customer List with Editable Counts
                              // Sub-customer List with Editable Counts
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 15),
                                    Text(
                                      "Sub Customers for ${meal['name']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7F4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ListView.separated(
                                        itemCount: _subCustomersList.length,
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        separatorBuilder:
                                            (_, __) => Divider(
                                              height: 1,
                                              color: Colors.grey.shade300,
                                            ),
                                        itemBuilder: (context, subIndex) {
                                          final sub =
                                              _subCustomersList[subIndex];
                                          final controller =
                                              _subCustomerControllers[subIndex];

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    sub['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 70,
                                                  child: TextField(
                                                    controller: controller,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 6,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      sub['orderCount'] =
                                                          int.tryParse(value) ??
                                                          0;

                                                      // Update meal's subCustomers list
                                                      meal['subCustomers'] =
                                                          _subCustomersList;

                                                      // Update total meal count dynamically for this meal
                                                      meal['mealCount'] =
                                                          _subCustomersList.fold<
                                                            int
                                                          >(
                                                            0,
                                                            (sum, s) =>
                                                                sum +
                                                                (s['orderCount']
                                                                        as int? ??
                                                                    0),
                                                          );

                                                      setState(
                                                        () {},
                                                      ); // Refresh UI
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                crossFadeState:
                                    isExpanded
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 300),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        if (_fromDate == null || _toDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select both From and To dates.',
                              ),
                              backgroundColor: Color(0xFFF15F28),
                            ),
                          );
                          return;
                        }

                        final enteredMeals =
                            mealTypes
                                .where((meal) => (meal['mealCount'] ?? 0) > 0)
                                .map(
                                  (meal) => {
                                    'id': meal['id'],
                                    'name': meal['name'],
                                    'mealCount': meal['mealCount'],
                                    "subCustomers":
                                        (meal['subCustomers'] ?? [])
                                            .map(
                                              (s) => {
                                                "id": s['id'],
                                                "name": s['name'],
                                                "orderCount":
                                                    s['orderCount'] ?? 0,
                                              },
                                            )
                                            .toList(),
                                  },
                                )
                                .toList();
                        print("📋 Entered Meals JSON: $enteredMeals");
                        if (enteredMeals.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter at least one meal count.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        // Format dates
                        String fromDateStr =
                            "${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}";
                        String toDateStr =
                            "${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}";

                        // Define all days (0–6 means Sunday–Saturday)
                        List<int> days = [];
                        DateTime current = _fromDate!;
                        while (current.isBefore(
                          _toDate!.add(const Duration(days: 1)),
                        )) {
                          days.add(current.weekday % 7);
                          // Flutter's weekday: Monday=1..Sunday=7 → backend expects 0=Sunday..6=Saturday
                          current = current.add(const Duration(days: 1));
                        }

                        // Prepare JSON body
                        final body = {
                          "companyId": int.parse(widget.companyId),
                          "meals": enteredMeals,
                          "orderDate": fromDateStr,
                          "toDate": toDateStr,
                          "day": days,
                        };

                        print("📦 Sending order data: $body");

                        try {
                          final response = await http.post(
                            Uri.parse(
                              '${AppConfig.localBaseUrl}/api/createOrderForAllMobile',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode(
                              body,
                            ), // make sure to encode the request body properly
                          );

                          final data = json.decode(response.body);

                          if (response.statusCode == 201 &&
                              data['status']['code'] == 201) {
                            // ✅ Move to “Order Placed” screen instead of new page
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else if (data['status']['code'] == 409) {
                            // ⚠️ Order already exists
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['status']['message'] ??
                                      "Order already exists",
                                ),
                                backgroundColor: Color(0xFFF15F28),
                              ),
                            );
                          } else {
                            // ❌ API error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['status']?['message'] ??
                                      'Failed to create order. Please try again.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          print("❌ Error placing order: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error connecting to server. Please try again.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15F28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "place_order".tr(),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    // Info text below button
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.red),
                          SizedBox(width: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "place_before".tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "4pm".tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Page 3: Order Placed
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "order_placed".tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "thank_you".tr(),
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        // ✅ Optionally go back to first screen
                        _pageController.jumpToPage(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15F28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back to Indent',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Page 3: Order Placed
          Positioned(
            bottom: 0,
            right: 30,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Opacity(
                opacity: 0.95,
                child: Transform.scale(
                  scale: 5.5, // make it bigger visually
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
