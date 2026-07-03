import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? driverDetails;

  const EditProfilePage({
    super.key,
    required this.username,
    this.driverDetails,
  });

  @override
  State<EditProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<EditProfilePage> {
  @override
  Widget build(BuildContext context) {
    final mobileNumber = widget.driverDetails?['mobileNumber'] ?? 'N/A';
    final address = widget.driverDetails?['address'] ?? 'N/A';
    final dob = widget.driverDetails?['dateOfBirth'] ?? 'N/A';
    final bloodGroup = widget.driverDetails?['bloodGroup'] ?? 'N/A';
    final licenceNumber =
        widget.driverDetails?['drivingLicenseNumber'] ?? 'N/A';
    final aadhaar = widget.driverDetails?['aadhaarNumber'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Header with gradient and profile picture
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4C53A5), Color(0xFF6C82B1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: -10,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 110,
                          backgroundImage: const AssetImage(
                            'assets/images/driver.png',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 🔹 Name and Company
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // const SizedBox(height: 6),
            // const SizedBox(height: 20),
            // 🔹 Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.phone,
                        "phone_number".tr(),
                        "+91 $mobileNumber",
                      ),
                      _infoTile(
                        Icons.location_on_outlined,
                        "address".tr(),
                        address,
                      ),
                      _infoTile(Icons.cake_outlined, "date_of_birth".tr(), dob),
                      _infoTile(
                        Icons.favorite_border,
                        "blood_group".tr(),
                        bloodGroup,
                      ),
                      _infoTile(
                        Icons.drive_eta,
                        "licence_number".tr(),
                        licenceNumber,
                      ),
                      _infoTile(
                        Icons.confirmation_number_rounded,
                        "aadhaar_number".tr(),
                        aadhaar,
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.language, color: Colors.blue),
                        ),
                        title: Text(
                          "change_language".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          _showLanguageChangeDialog();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showLanguageChangeDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("change_language".tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("English"),
                  onTap: () async {
                    await context.setLocale(const Locale('en'));
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
                ListTile(
                  title: const Text("தமிழ்"),
                  onTap: () async {
                    await context.setLocale(const Locale('ta'));
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[50],
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
      onTap: () {
        // Optional: show edit dialog for this field
      },
    );
  }
}
