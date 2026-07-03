import 'package:flutter/material.dart';

class PurchaseRequestDetailsPage extends StatelessWidget {
  final String companyId;

  const PurchaseRequestDetailsPage({Key? key, required this.companyId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PR Details"),
        backgroundColor: const Color(0xFF010440),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _row("PR Number", "PR-20260001"),
                    _divider(),

                    _row("Status", "Pending"),
                    _divider(),

                    _row("Kitchen", "Central Kitchen"),
                    _divider(),

                    _row("Category", "Non Perishable"),
                    _divider(),

                    _row("Request Date", "02 Jun 2026"),
                    _divider(),

                    _row("Required Date", "05 Jun 2026"),
                    _divider(),

                    _row("Requested By", "Admin"),
                    _divider(),

                    _row("Remarks", "Production Plan"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Requested Items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  _itemTile("Rice", "100 Kg", "₹4,500"),
                  const Divider(height: 1),

                  _itemTile("Cooking Oil", "20 L", "₹3,000"),
                  const Divider(height: 1),

                  _itemTile("Sugar", "50 Kg", "₹2,000"),
                  const Divider(height: 1),

                  _itemTile("Salt", "25 Kg", "₹1,500"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Total Amount",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "₹45,500",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const Text(": "),

          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }

  Widget _itemTile(String item, String qty, String amount) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xffFFF3E0),
        child: Icon(Icons.inventory_2, color: Colors.orange),
      ),
      title: Text(item),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text("Qty : $qty"), Text("Amount : $amount")],
      ),
    );
  }
}
