import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: TripDetailsPage()));

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int expandedIndex = -1;

  final trips = [
    {
      "status": "Ongoing",
      "from": "Paranur",
      "to": "Chengalpattu",
      "startTime": "10:00 AM",
      "endTime": "15:00 PM",
      "drops": [
        {
          "drop": "Drop 1",
          "time": "10:00 AM",
          "status": "Delivered",
          "eta": "10:45 AM",
        },
        {
          "drop": "Drop 2",
          "time": "10:00 AM",
          "status": "Delivered",
          "eta": "12:00 PM",
        },
        {
          "drop": "Drop 3",
          "time": "10:00 AM",
          "status": "In Transit",
          "eta": "12:45 PM",
        },
        {
          "drop": "Drop 4",
          "time": "10:00 AM",
          "status": "Pending",
          "eta": "13:00 PM",
        },
        {
          "drop": "Drop 5",
          "time": "10:00 AM",
          "status": "Pending",
          "eta": "14:30 PM",
        },
      ],
    },
    {
      "status": "Upcoming",
      "from": "Paranur",
      "to": "Mahendra City",
      "startTime": "10:00 AM",
      "endTime": "15:00 PM",
      "drops": [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trip Details",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final isExpanded = expandedIndex == index;
          final status = trip["status"];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  isExpanded
                      ? Border.all(color: Colors.blueAccent, width: 2)
                      : Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // 🔹 Header Row
                InkWell(
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? -1 : index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                status == "Ongoing"
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip["status"] as String,
                            style: TextStyle(
                              color:
                                  (trip["status"] == "Ongoing")
                                      ? Colors.green
                                      : Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Time + Route
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    trip["startTime"] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    trip["endTime"] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    trip["from"] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.local_shipping_outlined,
                                    color: Colors.deepOrange,
                                    size: 20,
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Colors.deepOrange,
                                      thickness: 1,
                                      indent: 8,
                                      endIndent: 8,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.home_outlined,
                                    color: Colors.deepOrange,
                                    size: 20,
                                  ),
                                  Text(
                                    trip["to"] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Expanded Drop Details
                if (isExpanded && (trip["drops"] as List).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: const Color(0xFFFDF8F6),
                    child: Column(
                      children:
                          (trip["drops"] as List).map((drop) {
                            final status = drop["status"];
                            IconData icon;
                            Color color;

                            switch (status) {
                              case "Delivered":
                                icon = Icons.check_circle;
                                color = Colors.green;
                                break;
                              case "In Transit":
                                icon = Icons.directions_bus;
                                color = Colors.orange;
                                break;
                              default:
                                icon = Icons.pending;
                                color = Colors.redAccent;
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, color: color, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${drop["drop"]} (${drop["time"]})",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${status == "Pending"
                                      ? "ETA"
                                      : status == "In Transit"
                                      ? "ETA"
                                      : "At"} ${drop["eta"]}",
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
