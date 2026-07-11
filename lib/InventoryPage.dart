import 'package:flutter/material.dart';

import 'PurchaseOrderPage.dart';
import 'PurchaseRequestPage.dart';

class InventoryPage extends StatelessWidget {
  final String companyId;
  final Set<String> inventoryRoles;

  InventoryPage({
    Key? key,
    required this.companyId,
    required this.inventoryRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleModules = modules.where((module) {
      return inventoryRoles.contains(module["title"]);
    }).toList();

    return Scaffold(
      // appBar: AppBar(
      // title: const Text("Inventory"),
      // backgroundColor: Colors.orange,
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Inventory Modules",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 6),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleModules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 5,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final module = visibleModules[index];

                return _menuCard(
                  context,
                  module["icon"] as IconData,
                  module["title"] as String,
                  module["color"] as Color,
                  count: module["count"] as int,
                  onTap: () => _openModule(context, module["title"] as String),
                  onAdd: () => _openModule(context, module["title"] as String),
                );
              },
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _openModule(BuildContext context, String title) {
    switch (title) {
      case "Purchase Request":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PurchaseRequestPage(companyId: companyId),
          ),
        );
        break;

      case "Purchase Order":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PurchaseOrderPage(companyId: companyId),
          ),
        );
        break;

      case "Goods Receipt":
        break;

      case "Purchase Invoice":
        break;

      case "Warehouse":
        break;

      case "Kitchen Request":
        break;

      case "Stock Transfer":
        break;

      case "Kitchen Stock":
        break;

      case "Consumption":
        break;

      case "Low Stock Items":
        break;

      case "Total Items":
        break;
    }
  }

  final modules = [
    {
      "title": "Purchase Request",
      "icon": Icons.description,
      "color": Colors.orange,
      "count": 12,
    },
    {
      "title": "Purchase Order",
      "icon": Icons.shopping_cart,
      "color": Colors.blue,
      "count": 8,
    },
    {
      "title": "Goods Receipt",
      "icon": Icons.inventory,
      "color": Colors.green,
      "count": 5,
    },
    {
      "title": "Purchase Invoice",
      "icon": Icons.receipt_long,
      "color": Colors.purple,
      "count": 6,
    },
    {
      "title": "Warehouse",
      "icon": Icons.warehouse,
      "color": Colors.brown,
      "count": 132,
    },
    {
      "title": "Kitchen Request",
      "icon": Icons.kitchen,
      "color": Colors.deepOrange,
      "count": 7,
    },
    {
      "title": "Stock Transfer",
      "icon": Icons.swap_horiz,
      "color": Colors.teal,
      "count": 4,
    },
    {
      "title": "Kitchen Stock",
      "icon": Icons.restaurant,
      "color": Colors.indigo,
      "count": 86,
    },
    {
      "title": "Consumption",
      "icon": Icons.local_dining,
      "color": Colors.orange,
      "count": 28,
    },
    {
      "title": "Low Stock Items",
      "icon": Icons.warning_amber,
      "color": Colors.redAccent,
      "count": 9,
    },
    {
      "title": "Total Items",
      "icon": Icons.inventory_2,
      "color": Colors.blueGrey,
      "count": 132,
    },
  ];

  Widget _menuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    int count = 0,
    VoidCallback? onTap,
    VoidCallback? onAdd,
  }) {
    return InkWell(
      onTap: onTap,
      // Open list page
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          child: Stack(
            children: [
              /// Plus Button
              Positioned(
                top: 5,
                right: 5,
                child: InkWell(
                  onTap: onAdd,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: color,
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ),

              /// Card Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(icon, color: color, size: 20),

                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
