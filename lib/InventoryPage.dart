import 'package:flutter/material.dart';

import 'PurchaseOrderPage.dart';
import 'PurchaseRequestPage.dart';

class InventoryPage extends StatelessWidget {
  final String companyId;

  const InventoryPage({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 5,
              mainAxisSpacing: 8,
              children: [
                _menuCard(
                  context,
                  Icons.description,
                  "Purchase Request",
                  Colors.orange,
                  count: 12,

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PurchaseRequestPage(companyId: companyId),
                      ),
                    );
                  },

                  onAdd: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PurchaseRequestPage(companyId: companyId),
                      ),
                    );
                  },
                ),

                _menuCard(
                  context,
                  Icons.shopping_cart,
                  "Purchase Order",
                  Colors.blue,
                  count: 8,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseOrderPage(companyId: companyId),
                      ),
                    );
                  },

                  onAdd: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseOrderPage(companyId: companyId),
                      ),
                    );
                  },
                ),

                _menuCard(
                  context,
                  Icons.inventory,
                  "Goods Receipt",
                  Colors.green,
                  count: 5,
                ),

                _menuCard(
                  context,
                  Icons.receipt_long,
                  "Purchase Invoice",
                  Colors.purple,
                  count: 6,
                ),

                _menuCard(
                  context,
                  Icons.warehouse,
                  "Warehouse",
                  Colors.brown,
                  count: 132,
                ),

                _menuCard(
                  context,
                  Icons.kitchen,
                  "Kitchen Request",
                  Colors.deepOrange,
                  count: 7,
                ),

                _menuCard(
                  context,
                  Icons.swap_horiz,
                  "Stock Transfer",
                  Colors.teal,
                  count: 4,
                ),

                _menuCard(
                  context,
                  Icons.restaurant,
                  "Kitchen Stock",
                  Colors.indigo,
                  count: 86,
                ),

                _menuCard(
                  context,
                  Icons.local_dining,
                  "Consumption",
                  Colors.orange,
                  count: 28,
                ),

                _menuCard(
                  context,
                  Icons.warning_amber,
                  "Low Stock Items",
                  Colors.redAccent,
                  count: 9,
                ),

                _menuCard(
                  context,
                  Icons.inventory_2,
                  "Total Items",
                  Colors.blueGrey,
                  count: 132,
                ),
              ],
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

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
