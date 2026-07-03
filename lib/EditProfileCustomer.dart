import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'GetStartedPage.dart';
import 'config_loader.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileCustomer extends StatefulWidget {
  final String companyId;
  final String phoneNumber; // NEW

  const EditProfileCustomer({
    super.key,
    required this.companyId,
    required this.phoneNumber,
  });

  @override
  State<EditProfileCustomer> createState() => _EditProfileCustomerState();
}

class _EditProfileCustomerState extends State<EditProfileCustomer> {
  Map<String, dynamic>? customerDetails;
  bool loading = true;
  Uint8List? profileImageBytes;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
  }

  Future<void> _pickAndUploadImage() async {
    // var status = await Permission.photos.request();

    // if (!status.isGranted) {
    //   print("⚠ Permission not granted");
    //   return;
    // }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    int? attachmentId = await _uploadAttachment(image);

    if (attachmentId != null) {
      await _updateUserAttachment(attachmentId);
      await _fetchCustomerDetails();
    }
  }

  Future<int?> _uploadAttachment(XFile file) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${AppConfig.localBaseUrl}/api/createAttachmentMobile"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse["data"]["id"]; // attachmentId
      }
    } catch (e) {
      print("❌ Upload error: $e");
    }
    return null;
  }

  Future<void> _updateUserAttachment(int attachmentId) async {
    try {
      final customerId = customerDetails?['id']; // from response

      final response = await http.put(
        Uri.parse(
          "${AppConfig.localBaseUrl}/api/updateCustomerUser/$customerId/$attachmentId",
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Profile image updated");
      } else {
        print("❌ Update failed");
      }
    } catch (e) {
      print("⚠ Error updating user: $e");
    }
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/getCustomerById/${widget.phoneNumber}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dataList = data['data'] as List<dynamic>?;

        if (dataList != null && dataList.isNotEmpty) {
          final customerData = dataList[0];
          final loginSessions =
              customerData['loginSession'] as List<dynamic>? ?? [];

          final firstCompanyName =
              loginSessions.isNotEmpty
                  ? loginSessions.first['companyName'] ?? ''
                  : '';

          final subCustomerNames = loginSessions
              .map((s) => s['subCustomerName'])
              .where((name) => name != null)
              .join(', ');

          setState(() {
            customerDetails = {
              'id': customerData['id'],
              'username': customerData['username'],
              'phoneNumber': customerData['phoneNumber'],
              'companyName': firstCompanyName,
              'subCustomerName': subCustomerNames,
              'attachmentId': customerData['attachmentId'],
            };
            loading = false;
          });
          final attachmentId = customerData['attachmentId'];

          if (attachmentId != null) {
            _downloadProfileImage(attachmentId);
          }
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _downloadProfileImage(int attachmentId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/attachmentDownloadMobile/$attachmentId',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          profileImageBytes = response.bodyBytes;
        });
      } else {
        print("❌ Failed to download customer image");
      }
    } catch (e) {
      print("⚠️ Error downloading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final username = customerDetails?['username'] ?? 'N/A';
    final phoneNumber = customerDetails?['phoneNumber'] ?? 'N/A';
    final companyName = customerDetails?['companyName'] ?? 'N/A';
    final rawSubCustomers = customerDetails?['subCustomerName'] ?? 'N/A';

    final subCustomerNames = rawSubCustomers
        .toString()
        .split(',')
        .map((e) => e.trim())
        .join(',\n');

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
                  colors: [Color(0xFF007BA7), Color(0xFF007BA7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // PROFILE IMAGE
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 75,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              profileImageBytes != null
                                  ? MemoryImage(profileImageBytes!)
                                  : null,
                          child:
                              profileImageBytes == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                    ),

                    // ✏️ EDIT ICON
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // boxShadow: [
                    //               BoxShadow(
                    //                 color: Colors.black.withOpacity(0.2),
                    //                 blurRadius: 4,
                    //               ),
                    //             ],
                    //           ),
                    //           child: const Icon(
                    //             Icons.edit,
                    //             color: Colors.white,
                    //             size: 20,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 🔹 Name and Company
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
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
                        "+91 $phoneNumber",
                      ),
                      const SizedBox(height: 12),
                      // _infoTile(Icons.password, "Username", username),
                      _infoTile(
                        Icons.business_outlined,
                        "zone".tr(),
                        companyName,
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        Icons.group_outlined,
                        "sub_customer".tr(),
                        subCustomerNames,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.language, color: Color(0xFF010440)),
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

                      // 🔻 Logout Option 🔻
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        title: Text(
                          "delete_account".tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                      ),
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

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[50],
        child: Icon(icon, color: Color(0xFF010440)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
      onTap: () {
        // Optional: show edit dialog for this field
      },
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("delete".tr()),
            content: Text("are_you_sure_delete".tr()),
            actions: [
              TextButton(
                child: Text("cancel".tr()),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  "delete".tr(),
                  style: const TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  final phoneNumber = widget.phoneNumber;

                  try {
                    final response = await http.delete(
                      Uri.parse(
                        "${AppConfig.localBaseUrl}/api/deleteUser/$phoneNumber",
                      ),
                      headers: {"Content-Type": "application/json"},
                    );

                    if (!mounted) return;

                    if (response.statusCode == 200) {
                      final jsonResponse = jsonDecode(response.body);
                      final message =
                          jsonResponse['status']['message'] ??
                          "Logout successful.";

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.green,
                        ),
                      );

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GetStartedPage(),
                        ),
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Logout failed: ${response.statusCode}",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Network error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
