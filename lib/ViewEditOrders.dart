import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config_loader.dart';

class ViewEditOrders extends StatefulWidget {
  final String companyId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String>? allowedSubCustomerIds;
  final bool isFsCustomer; // 👈 ADD THIS

  const ViewEditOrders({
    super.key,
    required this.companyId,
    required this.fromDate,
    required this.toDate,
    this.allowedSubCustomerIds,
    this.isFsCustomer = false,
  });

  @override
  State<ViewEditOrders> createState() => _ViewEditOrderScreenState();
}

class _ViewEditOrderScreenState extends State<ViewEditOrders> {
  String selectedDay = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  List<dynamic> meals = []; // ✅ Class-level meals list
  final Map<String, TextEditingController> subCustomerControllers = {};

  List<dynamic> feedbackMeals = [];
  List<dynamic> mealTypes = [];
  List<dynamic> itemTypes = [];
  bool _isLoading = false;
  final Map<int, TextEditingController> mainMealControllers = {};

  final Map<String, TextEditingController> controllers = {};

  // Total of all meals
  int getTotalMealCount() {
    return meals.fold(
      0,
      (sum, meal) => sum + ((meal['mealCount'] ?? 0) as int),
    );
  }

  final List<String> days = [];

  @override
  void initState() {
    super.initState();

    _fromDate = widget.fromDate;
    _toDate = widget.toDate;

    // Set selectedDay = fromDate's weekday
    selectedDay =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][_fromDate!.weekday -
            1];

    // Generate weekday list between from & to date
    final totalDays = widget.toDate.difference(widget.fromDate).inDays + 1;
    for (int i = 0; i < totalDays; i++) {
      final day = widget.fromDate.add(Duration(days: i));
      days.add(
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
      );
    }

    // Automatically fetch fromDate’s meal list when screen opens
    _fetchMealCountForDay(_fromDate!);
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateOrder() async {
    try {
      if (meals.isEmpty) return;

      final orderDate = _fromDate ?? DateTime.now(); // or selected day

      // Build payload array (one object per meal)
      final payload =
          meals
              .where((meal) {
                final subCustomers = meal['subCustomers'] as List;
                final hasSubOrders = subCustomers.any(
                  (sc) => (sc['orderCount'] ?? 0) > 0,
                );
                final mainMealHasCount =
                    subCustomers.isEmpty && (meal['mealCount'] ?? 0) > 0;
                return hasSubOrders || mainMealHasCount;
              })
              .map((meal) {
                final subCustomers =
                    (meal['subCustomers'] as List)
                        .where((sc) => (sc['orderCount'] ?? 0) > 0)
                        .map(
                          (sc) => {
                            "id": sc['id'],
                            "name": sc['name'],
                            "orderCount": sc['orderCount'],
                          },
                        )
                        .toList();

                return {
                  "mealCount": meal['mealCount'],
                  "companyId": widget.companyId,
                  "orderDate":
                      (_fromDate ?? DateTime.now()).toIso8601String().split(
                        "T",
                      )[0],
                  "mealId": meal['id'],
                  "meals": [
                    {
                      "id": meal['id'],
                      "name": meal['name'],
                      "mealCount": meal['mealCount'],
                      "na": false,
                      "subCustomers": subCustomers,
                    },
                  ],
                };
              })
              .toList();

      print('payload, $payload');

      if (payload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ No meals with orders to update')),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('${AppConfig.localBaseUrl}/api/updateOrderListForMobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload), // ✅ Must encode to JSON
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Order updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to update order: ${response.statusCode} ${response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Error updating order: $e')));
    }
  }

  Future<void> _fetchMealCountForDay(DateTime day) async {
    setState(() => _isLoading = true);

    try {
      final formattedDate =
          "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/orderListMobile/$formattedDate/$formattedDate/${widget.companyId}',
        ),
      );

      if (response.statusCode != 200) {
        print("❌ Failed to fetch meal counts: ${response.reasonPhrase}");
        return;
      }

      final jsonData = json.decode(response.body);

      final mealResponse = await http.get(
        Uri.parse('${AppConfig.localBaseUrl}/api/mealAllGetMobile/list'),
      );
      final mealJson = json.decode(mealResponse.body);
      final allMeals = (mealJson['data'] ?? []) as List;

      meals.clear();
      subCustomerControllers.clear();

      for (var order in jsonData['data'] ?? []) {
        for (var meal in order['meals'] ?? []) {
          final mealId = meal['id'];
          final matchedMeal = allMeals.firstWhere(
            (m) => m['id'] == mealId,
            orElse: () => null,
          );
          mainMealControllers[mealId] = TextEditingController(
            text: meal['mealCount'].toString(),
          );

          String? base64Image;
          if (matchedMeal != null && matchedMeal['uomId'] != null) {
            final attachmentId = matchedMeal['uomId'];
            try {
              final imageResponse = await http.get(
                Uri.parse(
                  '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
                ),
              );
              if (imageResponse.statusCode == 200) {
                base64Image = base64Encode(imageResponse.bodyBytes);
              }
            } catch (e) {
              print("⚠️ Error downloading image for meal $mealId: $e");
            }
          }

          // ✅ Apply sub-customer filter every time
          final List subCustomers = (meal['subCustomers'] ?? []);
          final filteredSubCustomers =
              widget.allowedSubCustomerIds != null &&
                      widget.allowedSubCustomerIds!.isNotEmpty
                  ? subCustomers
                      .where(
                        (sc) => widget.allowedSubCustomerIds!.contains(
                          sc['id'].toString(),
                        ),
                      )
                      .toList()
                  : subCustomers;

          meals.add({
            "id": mealId,
            "name": meal['name'],
            "mealCount": meal['mealCount'] ?? 0,
            "subCustomers": filteredSubCustomers,
            "isExpanded": false,
            "imageBytes": base64Image,
          });
        }
      }

      // controllers for text fields
      for (var meal in meals) {
        final mealId = meal['id'];
        for (var sc in meal['subCustomers']) {
          final scId = sc['id'];
          final key = "$mealId-$scId";
          subCustomerControllers[key] = TextEditingController(
            text: sc['orderCount'].toString(),
          );
        }
      }

      setState(() {});
      print("✅ Meal counts and images fetched for $formattedDate");
    } catch (e) {
      print("⚠️ Error fetching meal counts: $e");
    } finally {
      setState(() => _isLoading = false); // 🔹 Hide loader
    }
  }

  void _recalculateMainCount(int mealIndex) {
    final meal = meals[mealIndex];
    final subs = meal['subCustomers'] as List;

    int total = subs.fold<int>(
      0,
      (sum, sc) => sum + ((sc['orderCount'] ?? 0) as int),
    );

    setState(() {
      meal['mealCount'] = total;
      mainMealControllers[meal['id']]?.text = total.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "view_edit".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ),
        centerTitle: true,
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
                  fit: BoxFit.contain, // keeps full image visible
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Weekday selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        days.map((day) {
                          final isSelected = day == selectedDay;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(day),
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => selectedDay = day);

                                // Convert selected day to actual DateTime
                                final dayIndex = days.indexOf(day);
                                final selectedDate = widget.fromDate.add(
                                  Duration(days: dayIndex),
                                );

                                // Fetch meals for this day only
                                _fetchMealCountForDay(selectedDate);
                              },

                              selectedColor: const Color(0xFFF15F28),
                              backgroundColor: const Color(0xFFF5EDE7),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Meal list with expandable sub-customers
                Expanded(
                  child: ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      final isExpanded = meal['isExpanded'] ?? false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meal name + expand icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                meal['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                onPressed: () {
                                  setState(() {
                                    meal['isExpanded'] = !isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Meal image (same for all meals)
                          // Meal image with count overlay
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                // Meal image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      meal['imageBytes'] != null
                                          ? Image.memory(
                                            base64Decode(meal['imageBytes']),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                          : Image.network(
                                            'https://img.freepik.com/premium-photo/indian-thali-lunch-meal_57665-1479.jpg',
                                            // fallback
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                ),

                                // Count overlay
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SizedBox(
                                      width: 50,
                                      height: 32,
                                      child: TextField(
                                        controller:
                                            mainMealControllers[meal['id']],
                                        readOnly:
                                            meal['subCustomers'].isNotEmpty,
                                        // 🔥 KEY CHANGE
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          if (meal['subCustomers'].isEmpty) {
                                            meal['mealCount'] =
                                                int.tryParse(val) ?? 0;
                                            setState(() {});
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Sub-customer list (expandable)
                          if (isExpanded && meal['subCustomers'].isNotEmpty)
                            Column(
                              children:
                                  meal['subCustomers']
                                      .map<Widget>(
                                        (sc) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  sc['name'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),

                                              SizedBox(width: 10),

                                              SizedBox(
                                                width: 70,
                                                child: TextField(
                                                  controller:
                                                      subCustomerControllers["${meal['id']}-${sc['id']}"],
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (val) {
                                                    sc['orderCount'] =
                                                        int.tryParse(val) ?? 0;
                                                    _recalculateMainCount(
                                                      index,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),

                          const Divider(),
                        ],
                      );
                    },
                  ),
                ),

                // ✅ Total summary (count-based)
                const Divider(thickness: 1),

                _buildSummaryRow(
                  'Total Count',
                  getTotalMealCount().toDouble(),
                  isBold: true,
                  color: const Color(0xFFF15F28),
                ),

                const SizedBox(height: 20),

                // ✅ Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "update_order".tr(),
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
          if (_isLoading)
            Container(
              color: Colors.black45.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF15F28), // your theme color
                  strokeWidth: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
    String? valueText,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          Text(
            valueText ?? value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectOrderDateScreen extends StatefulWidget {
  final String companyId;
  final String? subCustomerId;
  final List<dynamic>? loginSessions; // 👈 new field for multiple subCustomers

  const SelectOrderDateScreen({
    super.key,
    required this.companyId,
    this.subCustomerId,
    this.loginSessions,
  });

  @override
  State<SelectOrderDateScreen> createState() => _SelectOrderDateScreenState();
}

class _SelectOrderDateScreenState extends State<SelectOrderDateScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    DateTime initialDate =
        isFrom
            ? (fromDate ?? DateTime.now())
            : (toDate ??
                (fromDate ?? DateTime.now()).add(const Duration(days: 1)));

    DateTime firstDate =
        isFrom ? DateTime(2024, 1) : fromDate ?? DateTime(2024, 1);
    DateTime lastDate =
        isFrom
            ? DateTime(2026, 12)
            : (fromDate != null
                ? fromDate!.add(const Duration(days: 6))
                : DateTime(2026, 12));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate, // ✅ disables dates beyond 7 days
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          fromDate = pickedDate;
          toDate = fromDate!.add(const Duration(days: 6)); // auto set toDate
        } else {
          toDate = pickedDate;
        }
      });
    }
  }

  void _goToNext() {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("please".tr())));
      return;
    }

    final List<String> allowedSubCustomers = [];

    if (widget.loginSessions != null) {
      for (var s in widget.loginSessions!) {
        if (s['subCustomerId'] != null) {
          allowedSubCustomers.add(s['subCustomerId'].toString());
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ViewEditOrders(
              companyId: widget.companyId,
              fromDate: fromDate!,
              toDate: toDate!,
              allowedSubCustomerIds: allowedSubCustomers, // 👈 pass list
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "select_date_range".tr(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
                  'assets/images/foodswing.jpg',
                  fit: BoxFit.contain, // keeps full image visible
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "from_date".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: _buildDateField(fromDate, "select_date".tr()),
                ),
                const SizedBox(height: 24),
                Text(
                  "to_date_max".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap:
                      fromDate == null
                          ? null
                          : () => _selectDate(context, false),
                  child: AbsorbPointer(
                    absorbing: fromDate == null,
                    child: _buildDateField(toDate, "select_date".tr()),
                  ),
                ),
                // const Spacer(),
                const SizedBox(height: 210),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF15F28),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "next".tr(),
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
          Positioned(
            bottom: 0,
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
          const Icon(Icons.calendar_today, color: const Color(0xFFF15F28)),
        ],
      ),
    );
  }
}
