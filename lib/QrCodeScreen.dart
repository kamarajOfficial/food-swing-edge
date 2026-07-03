import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeScreen extends StatelessWidget {
  final String username;

  const QrCodeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      // appBar: AppBar(
      //   title: const Text("Your QR Code"),
      //   backgroundColor: const Color(0xFF4C53A5),
      //   centerTitle: true,
      //   elevation: 0,
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 🔹 User Info
              CircleAvatar(
                radius: 50,
                backgroundImage: const AssetImage('assets/images/driver.png'),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // 🔹 QR Code Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: QrImageView(
                    data: "driverA@okaxis",
                    size: 200.0,
                    backgroundColor: Colors.white,
                    // you can also use foregroundColor, embeddedImage, etc depending on support
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Copy / Share buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("qr_data".tr())));
                      },
                      icon: const Icon(Icons.copy),
                      label: Text("copy".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8F8F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share("driver_qr".tr());
                      },
                      icon: const Icon(Icons.share),
                      label: Text("share".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15F28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
