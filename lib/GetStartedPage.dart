import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'LabelPrint.dart';
import 'ProductionApproval.dart';
import 'Wastage.dart';
import 'sampleLogin.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile.dart';
import 'trackPage.dart';
import 'tripPage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'DriverHomePage.dart';
import 'EditProfileCustomer.dart';
import 'FsAttendancePage.dart';
import 'FsHomePage.dart';
import 'FsLabelPrint.dart';
import 'FsOrderPage.dart';
import 'InventoryPage.dart';
import 'QrCodeScreen.dart';
import 'ViewEditOrders.dart';
import 'config_loader.dart';
import 'homePage.dart';
import 'menuPage.dart';
import 'orderPage.dart';
import 'EditProfileFsCustomer.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login.jpg', fit: BoxFit.cover),
          // Container(
          //   color: Colors.black.withOpacity(0.3),
          // ),
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (context.locale.languageCode == 'en') {
                  context.setLocale(const Locale('ta'));
                } else {
                  context.setLocale(const Locale('en'));
                }
              },
              child: Text(
                context.locale.languageCode == 'en' ? "தமிழ்" : "English",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 4.0),
                      // Scale from 80% to 120%
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Image.asset(
                            'assets/images/sauceit.png',
                            height: 80,
                            width: 280,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                      onEnd: () {
                        // Repeat the scale effect (optional bounce)
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 2),
                Text(
                  "get_started_text".tr(),
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF15F28),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneLoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    "get_started".tr(),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _phoneController.text.length == 10 &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Future<String> _getDeviceId() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //
  //   if (Platform.isAndroid) {
  //     final info = await deviceInfo.androidInfo;
  //     return info.id; // Android unique ID
  //   } else if (Platform.isIOS) {
  //     final info = await deviceInfo.iosInfo;
  //     return info.identifierForVendor ?? "";
  //   }
  //   return "";
  // }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  Future<http.Response?> saveLoginToMatchingServer(
    Map<String, dynamic> payload,
  ) async {
    for (final baseUrl in AppConfig.allBaseUrls) {
      try {
        print("Trying saveLogin -> $baseUrl");

        final response = await http
            .post(
              Uri.parse("$baseUrl/api/saveLogin"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        final json = jsonDecode(response.body);

        final status = json["status"];

        if (status["code"] == 200 && json["data"] != null) {
          AppConfig.setApiBaseUrl(baseUrl);

          print("Matched : $baseUrl");

          return response;
        }
      } catch (e) {
        print("Failed : $baseUrl");
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 2.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Image.asset(
                      'assets/images/sauceit.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "welcome_back".tr(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "sign_in_message".tr(),
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 40),
                // 🔒 Password field with label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "username".tr(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                TextField(
                  controller: _passwordController,
                  // obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "enter_your_username".tr(),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 📞 Phone field with label and single box
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "phone_number".tr(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: "",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "+91 ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    hintText: "enter_your_phone_number".tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Continue button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonEnabled
                        ? const Color(0xFFF15F28)
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isButtonEnabled
                      ? () async {
                          final phone = _phoneController.text.trim();
                          final password = _passwordController.text.trim();

                          try {
                            // 🔥 Fetch device ID
                            final deviceId = await _getDeviceId();
                            print("DeviceID: $deviceId");

                            // ✅ Prepare payload WITH deviceId
                            final payload = {
                              "phoneNumber": int.parse(phone),
                              "username": password,
                              "deviceId": deviceId, // 👈 ADD THIS
                            };

                            print("Payload: $payload");

                            // ✅ Make API request
                            final response = await saveLoginToMatchingServer(
                              payload,
                            );

                            if (response == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Unable to connect to any server",
                                  ),
                                ),
                              );
                              return;
                            }

                            final jsonResponse = jsonDecode(response.body);

                            final message = jsonResponse['status']['message'];
                            final data =
                                jsonResponse['data']; // may be null for some cases
                            if (response.statusCode == 200) {
                              // ✅ Case 1: DRIVER LOGIN
                              if (message ==
                                      "Phone number belongs to a driver." &&
                                  data != null) {
                                final phoneNumber = data['phoneNumber']
                                    .toString();

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MainTabPage(
                                      username: phoneNumber,
                                      companyId: '',
                                      companyName: "Driver",
                                      subCustomerId: '',
                                      phoneNumber: phoneNumber,
                                      loginSessions: const [],
                                      isDriver: true,
                                    ),
                                  ),
                                  (route) =>
                                      false, // remove all previous routes
                                );
                              }
                              // ✅ Case 2: Foodswing user login (No need to check loginSession availability)
                              if (message == "Foodswing user login" &&
                                  data != null) {
                                final loginSessions =
                                    data['loginSession'] as List<dynamic>? ??
                                    [];
                                final phoneNumber = data['phoneNumber'];

                                // Extract company names safely
                                final uniqueCompanies =
                                    <String, Map<String, String>>{};

                                for (var session in loginSessions) {
                                  final id = session["companyId"].toString();
                                  final name = session["companyName"]
                                      .toString();

                                  // Insert only if not seen already
                                  uniqueCompanies[id] = {
                                    "companyId": id,
                                    "companyName": name,
                                  };
                                }

                                final companies = uniqueCompanies.values
                                    .toList();

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FsAnimationScreen(
                                      username: data['username'].toString(),
                                      companies: companies,
                                      companyId: "",
                                      subCustomerId: '',
                                      phoneNumber: phoneNumber,
                                      loginSessions: loginSessions,
                                      // even if empty
                                      isDriver: false,
                                      isFsCustomer:
                                          message ==
                                          "Foodswing user login", // always true for this case
                                    ),
                                  ),
                                );
                                return; // Stop other checks
                              }

                              // ✅ Case 1: Already approved
                              if (message ==
                                      "This phone number is already approved and active." &&
                                  data != null) {
                                final loginSessions =
                                    data['loginSession'] as List<dynamic>?;

                                if (loginSessions != null &&
                                    loginSessions.isNotEmpty) {
                                  final phoneNumber = data['phoneNumber'];

                                  // Extract all company names (avoid duplicates)
                                  final companyNames = loginSessions
                                      .map(
                                        (s) =>
                                            s['companyName']?.toString() ?? '',
                                      )
                                      .toSet()
                                      .toList();

                                  // ✅ Pass the entire loginSession list to the next screen
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StalinAnimationScreen(
                                        username: data['username'].toString(),
                                        // or any display name
                                        companies: companyNames,
                                        companyId: loginSessions
                                            .first['companyId']
                                            .toString(),
                                        subCustomerId: '',
                                        // not needed if multiple
                                        phoneNumber: phoneNumber,
                                        loginSessions:
                                            loginSessions, // 👈 pass full list
                                      ),
                                    ),
                                  );
                                } else {
                                  // Handle case where no login sessions are returned
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No active sub-customer sessions found.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                              // ✅ Case 2: Pending approval
                              else if (message == "Pending for Approval") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Pending for approval. Please wait for admin approval.",
                                    ),
                                    backgroundColor: Color(0xFFF15F28),
                                  ),
                                );
                              }
                              // ✅ Case 3: OTP sent — Go to OTP Page
                              else if (message ==
                                  "User registered successfully. OTP sent to phone.") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpVerificationPage(
                                      phoneNumber: phone,
                                      username: password,
                                    ),
                                  ),
                                );
                              } else if (message == "New OTP generated.") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpVerificationPage(
                                      phoneNumber: phone,
                                      username: password,
                                    ),
                                  ),
                                );
                              }
                              // ✅ Unknown case
                              else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Server Error: ${response.statusCode}",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Network error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    "continue".tr(),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 150),
                const Text(
                  "Version info 1.0.0",
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Support contact",
                  style: TextStyle(
                    color: Color(0xFFF15F28),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String username;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.username,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;
  bool _selectAll = false;
  final List<MultiSelectItem<String>> _designationItems = [];

  List<dynamic> _subCustomers = [];
  String? _selectedCompany;
  List<String> _selectedSubCustomers = [];
  final List<String> _designations = [
    "aee_name",
    "so_name",
    "ae_name",
    "si_name",
  ];

  List<String> _selectedDesignations = [];

  // ✅ Replace with your real backend URL
  final String apiUrl =
      "${AppConfig.localBaseUrl}/api/getSubCustomerMasterMobile";

  Future<void> _fetchSubCustomers() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status']['code'] == 200) {
          setState(() {
            _subCustomers = jsonResponse['data'];
          });
        } else {
          _showError('Failed to load data');
        }
      } else {
        _showError('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<String> get _companies {
    final companyNames = _subCustomers
        .map((e) => e['uomName'].toString())
        .toSet()
        .toList();
    companyNames.sort();
    return companyNames;
  }

  List<Map<String, dynamic>> get _filteredSubCustomers {
    if (_selectedCompany == null) return [];
    return _subCustomers
        .where((e) => e['uomName'] == _selectedCompany)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchSubCustomers();
    _designationItems.addAll(
      _designations.map((d) => MultiSelectItem<String>(d, d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // IconButton(
                          //   // icon: const Icon(Icons.arrow_back),
                          //   onPressed: () => Navigator.pop(context),
                          // ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.topRight,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.9, end: 2.0),
                              // scale range
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Image.asset(
                                'assets/images/sauceit.png',
                                height: 80, // make it larger
                                fit: BoxFit.contain,
                              ),
                              onEnd: () {
                                // Optional: To make it loop, use a StatefulWidget + reverse animation
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "Enter Code",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => SizedBox(
                            width: 55,
                            height: 55,
                            child: TextField(
                              controller: _otpControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: "",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 3) {
                                  FocusScope.of(context).nextFocus();
                                }
                                if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).previousFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: () {
                          // OPEN THE MULTI SELECT DIALOG
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return MultiSelectDialog(
                                items: _designationItems,
                                initialValue: _selectedDesignations,
                                title: Text("select_designations".tr()),
                                selectedColor: const Color(0xFFF15F28),
                                height: 250,
                                width: 300,
                                onConfirm: (values) {
                                  setState(() {
                                    _selectedDesignations = values
                                        .cast<String>();
                                  });
                                },
                              );
                            },
                          );
                        },

                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            spacing: 10, // space between columns
                            runSpacing: 0, // space between rows
                            children: [
                              if (_selectedDesignations.isEmpty)
                                Text(
                                  "select_designations".tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),

                              // Chips in fixed-width boxes (2 per row)
                              ..._selectedDesignations.map((d) {
                                return SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width - 90) /
                                      2, // 2 columns
                                  child: Chip(
                                    label: Text(
                                      d,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    backgroundColor: const Color(
                                      0xFFF15F28,
                                    ).withOpacity(0.2),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFFF15F28),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Color(0xFFF15F28),
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedDesignations.remove(d);
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: Color(0xFFF15F28),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              // dropdown arrow aligned right
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ✅ Company dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCompany,
                        decoration: InputDecoration(
                          labelText: "select_company".tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _companies
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCompany = value;
                            _selectedSubCustomers = [];
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // ✅ Sub-customer dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "select_sub_customers".tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // "Select All" checkbox
                          CheckboxListTile(
                            title: Text(
                              "select_all".tr(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            value: _selectAll,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              setState(() {
                                _selectAll = checked ?? false;

                                if (_selectAll) {
                                  // Select all
                                  _selectedSubCustomers = _filteredSubCustomers
                                      .map((e) => e['name'] as String)
                                      .toList();
                                } else {
                                  // Unselect all
                                  _selectedSubCustomers.clear();
                                }
                              });
                            },
                          ),

                          // Sub-customer checkboxes
                          ..._filteredSubCustomers.map((sub) {
                            final name = sub['name'] as String;
                            final isSelected = _selectedSubCustomers.contains(
                              name,
                            );
                            return CheckboxListTile(
                              title: Text(name),
                              value: isSelected,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedSubCustomers.add(name);
                                  } else {
                                    _selectedSubCustomers.remove(name);
                                  }

                                  // Auto-update "Select All"
                                  _selectAll =
                                      _selectedSubCustomers.length ==
                                      _filteredSubCustomers.length;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF15F28),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            (_selectedCompany != null &&
                                _selectedSubCustomers.isNotEmpty &&
                                _selectedDesignations.isNotEmpty)
                            ? () async {
                                final otp = _otpControllers
                                    .map((c) => c.text)
                                    .join();
                                if (otp.length != 4) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("otp".tr()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                // 👉 ADD THIS VALIDATION HERE
                                if (_selectedDesignations.isEmpty) {
                                  _showError(
                                    "Please select at least one designation!",
                                  );
                                  return;
                                }

                                final selectedSessions = _filteredSubCustomers
                                    .where(
                                      (e) => _selectedSubCustomers.contains(
                                        e['name'],
                                      ),
                                    )
                                    .map(
                                      (e) => {
                                        "id": 0,
                                        "userId": 0,
                                        "companyId": e['uomId'],
                                        "subCustomerId": e['id'],
                                      },
                                    )
                                    .toList();

                                final payload = {
                                  "otp": otp,
                                  "phoneNumber": int.parse(widget.phoneNumber),
                                  "officers": _selectedDesignations.join(","),
                                  "loginSession": selectedSessions,
                                };

                                setState(() => _isLoading = true);

                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                      "${AppConfig.localBaseUrl}/api/verifyOtp",
                                    ),
                                    headers: {
                                      "Content-Type": "application/json",
                                    },
                                    body: jsonEncode(payload),
                                  );

                                  final jsonResponse = jsonDecode(
                                    response.body,
                                  );

                                  if (response.statusCode == 200 &&
                                      jsonResponse['status']['code'] == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "OTP verified successfully. Waiting for admin approval...",
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // ⏳ Wait so user can read the message
                                    await Future.delayed(
                                      const Duration(seconds: 2),
                                    );
                                    // ✅ Navigate and pass all selected sessions
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GetStartedPage(
                                          // 👈 pass the full list
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showError(
                                      jsonResponse['status']['message'] ??
                                          'Invalid OTP, please try again',
                                    );
                                  }
                                } catch (e) {
                                  _showError('Network error: $e');
                                }

                                setState(() => _isLoading = false);
                              }
                            : null,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "sign_in".tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class StalinAnimationScreen extends StatefulWidget {
  final String username;
  final List<String> companies;
  final String companyId;
  final String subCustomerId;
  final String phoneNumber;
  final List<dynamic>? loginSessions; // 👈 Add this
  final bool isDriver;
  final bool isFsCustomer; // ✅ new flag

  const StalinAnimationScreen({
    super.key,
    required this.username,
    required this.companies,
    required this.companyId,
    required this.subCustomerId,
    required this.phoneNumber,
    this.loginSessions, // 👈 optional
    this.isDriver = false,
    this.isFsCustomer = false, // default false
  });

  @override
  State<StalinAnimationScreen> createState() => _StalinAnimationScreenState();
}

class _StalinAnimationScreenState extends State<StalinAnimationScreen> {
  bool _showFirst = true;

  @override
  void initState() {
    super.initState();

    // Toggle between two images every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() => _showFirst = !_showFirst);
    });

    // After 4 seconds, navigate to MainTabPage
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainTabPage(
              username: widget.username,
              companyId: widget.companyId,
              companyName: widget.companies.first,
              subCustomerId: widget.subCustomerId,
              phoneNumber: widget.phoneNumber,
              loginSessions: widget.loginSessions,
              isDriver: widget.isDriver,
              isFsCustomer: widget.isFsCustomer, // ✅ Add this
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Image.asset(
            _showFirst
                ? 'assets/images/food treaser.png'
                : 'assets/images/stalin treaser.png',
            key: ValueKey<bool>(_showFirst),
            width: 400,
            height: 280,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class FsAnimationScreen extends StatefulWidget {
  final String username;
  final List<Map<String, String>> companies;
  final String companyId;
  final String subCustomerId;
  final String phoneNumber;
  final List<dynamic>? loginSessions;
  final bool isDriver;
  final bool isFsCustomer;

  const FsAnimationScreen({
    super.key,
    required this.username,
    required this.companies,
    required this.companyId,
    required this.subCustomerId,
    required this.phoneNumber,
    this.loginSessions,
    this.isDriver = false,
    this.isFsCustomer = false,
  });

  @override
  State<FsAnimationScreen> createState() => _FsAnimationScreenState();
}

class _FsAnimationScreenState extends State<FsAnimationScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-navigation after 31 seconds
    Future.delayed(const Duration(seconds: 31), () {
      if (!mounted) return;
      _goToNextPage();
    });
  }

  void _goToNextPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCompanyPage(
          username: widget.username,
          companies: widget.companies,
          phoneNumber: widget.phoneNumber,
          subCustomerId: widget.subCustomerId,
          loginSessions: widget.loginSessions!,
          isDriver: widget.isDriver,
          isFsCustomer: widget.isFsCustomer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animation GIF
          Center(
            child: Image.asset(
              'assets/images/sauceitvideo.gif',
              key: const ValueKey("fs_animation"),
              width: 400,
              height: 280,
              fit: BoxFit.contain,
            ),
          ),

          // Skip Button (Top Right)
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _goToNextPage,
              child: Text(
                "skip".tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectCompanyPage extends StatefulWidget {
  final String username;
  final List<Map<String, String>> companies;
  final String subCustomerId;
  final String phoneNumber;
  final List<dynamic> loginSessions;
  final bool isDriver;
  final bool isFsCustomer; // ✅ new flag

  const SelectCompanyPage({
    super.key,
    required this.username,
    required this.companies,
    required this.subCustomerId,
    required this.phoneNumber,
    required this.loginSessions,
    this.isDriver = false,
    this.isFsCustomer = false, // default false
  });

  @override
  State<SelectCompanyPage> createState() => _SelectCompanyPageState();
}

class _SelectCompanyPageState extends State<SelectCompanyPage> {
  String? selectedCompanyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // title: const Text("Select Company"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // 🔥 reduce padding
        child: Column(
          children: [
            SizedBox(
              width: double.infinity, // 🔥 Makes dropdown take full width
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "choose_company".tr(),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                items: widget.companies.map((c) {
                  return DropdownMenuItem(
                    value: c["companyId"],
                    child: Text(
                      c["companyName"] ?? '',
                      overflow: TextOverflow.ellipsis, // 🔥 Prevent overflow
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCompanyId = value);
                },
              ),
            ),

            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: selectedCompanyId == null
                  ? null
                  : () {
                      final selectedCompany = widget.companies.firstWhere(
                        (c) => c["companyId"] == selectedCompanyId,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainTabPage(
                            username: widget.username,
                            companyId: selectedCompanyId!,
                            companyName: selectedCompany["companyName"]!,
                            subCustomerId: widget.subCustomerId,
                            phoneNumber: widget.phoneNumber,
                            loginSessions: widget.loginSessions,
                            isDriver: widget.isDriver,
                            isFsCustomer: widget.isFsCustomer,
                          ),
                        ),
                      );
                    },
              child: Text("continue").tr(),
            ),
          ],
        ),
      ),
    );
  }
}

class MainTabPage extends StatefulWidget {
  final String username;
  final String companyId;
  final String companyName;
  final String subCustomerId;
  final String phoneNumber;
  final List<dynamic>? loginSessions;
  final bool isDriver; // 👈 add this
  final bool isFsCustomer; // ✅ new flag

  const MainTabPage({
    super.key,
    required this.username,
    required this.companyId,
    required this.companyName,
    required this.subCustomerId,
    required this.phoneNumber,
    this.loginSessions,
    this.isDriver = false, // default false
    this.isFsCustomer = false, // default false
  });

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  Map<String, dynamic>? _driverDetails;
  Map<String, dynamic>? _customerDetails;
  String? _displayName;
  String? _driverId; // 👈 store fetched driverId
  Set<String> _roles = {};
  Set<String> _inventoryRoles = {};

  @override
  void initState() {
    super.initState();

    print("🔹 MainTabPage initState called for phone: ${widget.phoneNumber}");

    if (widget.isDriver) {
      print("🚗 User is a driver. Fetching driver details...");
      _fetchDriverDetails(widget.phoneNumber);
      return;
    }

    if (widget.isFsCustomer) {
      print("🟢 Foodswing user detected. Fetching FS customer details...");
      _fetchCustomerFsDetails(widget.phoneNumber);
    } else {
      print(
        "🔵 Normal/approved customer detected. Fetching customer details...",
      );
      _fetchCustomerDetails(widget.phoneNumber);
    }
  }

  // ✅ Fetch driver details using phone number
  Future<void> _fetchDriverDetails(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.localBaseUrl}/api/getMobileDriverById/$phoneNumber',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final driverData = data['data'];

        if (driverData != null) {
          setState(() {
            _driverId = driverData['driverId']?.toString(); // 👈 store driverId
            _displayName = driverData['fullName'] ?? '';

            // Store extra driver info
            _driverDetails = {
              'mobileNumber': driverData['mobileNumber'] ?? '',
              'address': driverData['address'] ?? '',
              'dateOfBirth': driverData['dateOfBirth'] ?? '',
              'bloodGroup': driverData['bloodGroup'] ?? '',
              'drivingLicenseNumber': driverData['drivingLicenseNumber'] ?? '',
              'aadhaarNumber': driverData['aadhaarNumber'] ?? '',
            };

            _buildDriverPages(); // 👈 build pages once data is ready
          });
        }
      } else {
        print('❌ Failed to fetch driver details: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error fetching driver details: $e');
    }
  }

  // ✅ Build driver-specific pages
  void _buildDriverPages() {
    _pages = [
      DriverHomePage(driverId: _driverId ?? ''), // 👈 use driverId
      TripListPage(driverId: _driverId ?? ''), // 👈 use driverId
      QrCodeScreen(username: _displayName ?? widget.username),
      EditProfilePage(
        username: _displayName ?? widget.username,
        driverDetails: _driverDetails,
      ),
    ];

    _navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "home".tr()),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on_rounded),
        label: "trip".tr(),
      ),
      BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: "qr".tr()),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "profile".tr()),
    ];
  }

  Future<void> _fetchCustomerDetails(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.localBaseUrl}/api/getCustomerById/$phoneNumber'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dataList = data['data'] as List<dynamic>?;

        if (dataList != null && dataList.isNotEmpty) {
          final customerData = dataList[0];
          final loginSessions =
              customerData['loginSession'] as List<dynamic>? ?? [];

          // ✅ Extract first company name (you can change logic if needed)
          final firstCompanyName = loginSessions.isNotEmpty
              ? loginSessions.first['companyName'] ?? ''
              : '';

          // ✅ Extract all sub-customer names as comma-separated list
          final subCustomerNames = loginSessions
              .map((session) => session['subCustomerName'])
              .where((name) => name != null)
              .join(', ');

          setState(() {
            _customerDetails = {
              'phoneNumber': customerData['phoneNumber'] ?? '',
              'username': customerData['username'] ?? '',
              'companyName': firstCompanyName,
              'subCustomerName': subCustomerNames, // ✅ Added this
            };

            _buildCustomerPages(); // build pages once data is ready
          });
        }
      } else {
        print('❌ Failed to fetch customer details: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error fetching customer details: $e');
    }
  }

  Future<http.Response?> saveCustomerUserMatchingServer(
    String phoneNumber,
  ) async {
    for (final baseUrl in AppConfig.allBaseUrls) {
      try {
        print("Trying Customer API -> $baseUrl");

        final response = await http
            .get(Uri.parse("$baseUrl/api/getCustomerFsById/$phoneNumber"))
            .timeout(const Duration(seconds: 5));

        print(response.body);

        final json = jsonDecode(response.body);

        final status = json["status"];
        final data = json["data"] as List?;

        if (status != null &&
            status["code"] == 200 &&
            data != null &&
            data.isNotEmpty) {
          AppConfig.setApiBaseUrl(baseUrl);

          print("Matched Customer Server : $baseUrl");

          return response;
        }
      } catch (e) {
        print("Failed : $baseUrl");
        print(e);
      }
    }

    return null;
  }

  Future<void> _fetchCustomerFsDetails(String phoneNumber) async {
    try {
      final response = await saveCustomerUserMatchingServer(phoneNumber);

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to connect to any server")),
        );
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dataList = data['data'] as List<dynamic>?;

        if (dataList != null && dataList.isNotEmpty) {
          final customerData = dataList[0];
          final userCode = customerData["code"] ?? "";
          String organization = "";

          if (userCode.startsWith("FS")) {
            organization = "FS";
          } else if (userCode.startsWith("JAN")) {
            organization = "JAN";
          } else if (userCode.startsWith("GCC")) {
            organization = "GCC";
          }

          AppConfig.setBaseUrl(organization);

          print("API Base URL : ${AppConfig.apiBaseUrl}");
          print("Local Base URL : ${AppConfig.localBaseUrl}");

          final loginSessions =
              customerData['loginSession'] as List<dynamic>? ?? [];

          final selectedCompany = loginSessions.firstWhere(
            (s) => s['companyId'].toString() == widget.companyId,
            orElse: () => null,
          );

          final selectedCompanyName = selectedCompany != null
              ? selectedCompany['companyName']
              : '';

          // // ✅ Extract all sub-customer names as comma-separated list
          // final subCustomerNames = loginSessions
          //     .map((session) => session['subCustomerName']?.toString().trim())
          //     .where(
          //       (name) => name != null && name!.isNotEmpty,
          //     ) // filter null + empty
          //     .join(', ');
          final roleString = customerData['role'] ?? '';

          _roles = roleString
              .toString()
              .split(',')
              .map<String>((e) => e.trim())
              .toSet();

          final inventoryRoleString =
              customerData['inventoryRole']?.toString() ?? '';

          _inventoryRoles = inventoryRoleString
              .split(',')
              .map<String>((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet();

          setState(() {
            _customerDetails = {
              'phoneNumber': customerData['phoneNumber'] ?? '',
              'username': customerData['username'] ?? '',
              'companyName': selectedCompanyName,
              // 'subCustomerName': subCustomerNames, // ✅ Added this
            };

            _buildCustomerFsPages(); // build pages once data is ready
          });
        }
      } else {
        print('❌ Failed to fetch customer details: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error fetching customer details: $e');
    }
  }

  // ✅ Build customer pages
  void _buildCustomerPages() {
    _pages = [
      HomePage(
        companyId: widget.companyId,
        loginSessions: widget.loginSessions,
      ),
      OrdersPage(
        username: widget.username,
        companyId: widget.companyId,
        companyName: widget.companyName,
        loginSessions: widget.loginSessions,
      ),
      SelectOrderDateScreen(
        companyId: widget.companyId,
        loginSessions: widget.loginSessions,
      ),
      LabelMealSelectionPage(
        companyId: widget.companyId,
        loginSessions: widget.loginSessions,
      ),
      TrackOrderPage(companyId: widget.companyId),
      MenuPage(
        companyId: widget.companyId,
        isFsCustomer: widget.isFsCustomer,
        username: widget.username,
      ),
      EditProfileCustomer(
        companyId: widget.companyId,
        phoneNumber: widget.phoneNumber,
      ),
    ];

    _navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "home".tr()),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: "indent".tr(),
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.mode_edit_outline_rounded),
        label: "edit_indent".tr(),
      ),
      BottomNavigationBarItem(icon: Icon(Icons.print), label: "label".tr()),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: "track".tr(),
      ),
      BottomNavigationBarItem(icon: Icon(Icons.menu), label: "menu".tr()),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle_rounded),
        label: "account".tr(),
      ),
    ];
  }

  void _buildCustomerFsPages() {
    _pages = [];
    _navItems = [];

    // ✅ HOME (always)
    if (_roles.contains("Home")) {
      _pages.add(
        FsHomePage(
          companyId: widget.companyId,
          loginSessions: widget.loginSessions,
          username: widget.username,
          roles: _roles, // 👈 pass roles here
        ),
      );
      _navItems.add(
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "home".tr()),
      );
    }

    // ✅ INDENT
    if (_roles.contains("Indent")) {
      _pages.add(
        FsOrdersPage(
          companyId: widget.companyId,
          loginSessions: widget.loginSessions,
          username: widget.username,
          isFsCustomer: widget.isFsCustomer,
        ),
      );
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "indent".tr(),
        ),
      );
    }

    // ✅ APPROVAL
    if (_roles.contains("Approval")) {
      _pages.add(ProductionApprovalPage(companyId: widget.companyId));
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.approval),
          label: "approval".tr(),
        ),
      );
    }

    // ✅ WASTAGE
    if (_roles.contains("Wastage")) {
      _pages.add(WastageMealSelectionPage(companyId: widget.companyId));
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          label: "wastage".tr(),
        ),
      );
    }

    // ✅ LABEL
    if (_roles.contains("Label")) {
      _pages.add(FsLabelMealSelectionPage(companyId: widget.companyId));
      _navItems.add(
        BottomNavigationBarItem(icon: Icon(Icons.print), label: "label".tr()),
      );
    }

    // ✅ TRACK
    if (_roles.contains("Track")) {
      _pages.add(TrackOrderPage(companyId: widget.companyId));
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: "track".tr(),
        ),
      );
    }

    // ✅ INVENTORY
    if (_roles.contains("Inventory")) {
      _pages.add(
        InventoryPage(
          companyId: widget.companyId,
          inventoryRoles: _inventoryRoles,
          username: widget.username,
        ),
      );
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: "inventory",
        ),
      );
    }

    // ✅ MENU (always)
    if (_roles.contains("Menu")) {
      _pages.add(
        MenuPage(
          companyId: widget.companyId,
          isFsCustomer: widget.isFsCustomer,
          username: widget.username,
        ),
      );
      _navItems.add(
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: "menu".tr()),
      );
    }

    if (_roles.contains("Attendance")) {
      _pages.add(AttendancePage(companyId: widget.companyId));
      _navItems.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.fingerprint),
          label: "attendance".tr(),
        ),
      );
    }

    // ✅ ACCOUNT (always)
    _pages.add(
      EditProfileFsCustomer(
        companyId: widget.companyId,
        phoneNumber: widget.phoneNumber,
      ),
    );
    _navItems.add(
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle_rounded),
        label: "account".tr(),
      ),
    );

    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDriver && _driverId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final localizedNavItems = _navItems;

    // For customers: wait until customerDetails is fetched
    if (!widget.isDriver && _customerDetails == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF010440),
        automaticallyImplyLeading: false,
        // iconTheme: const IconThemeData(
        //   color: Colors.white, // 👈 makes the back arrow white
        // ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HELLO ${(_displayName ?? widget.username).toString().toUpperCase()},',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.companyName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_sharp, color: Colors.white),
            tooltip: 'Support',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    "for_more".tr(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: Colors.indigoAccent,
                        size: 48,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "customer_support".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '+91 73050 46337',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFF15F28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "close".tr(),
                        style: TextStyle(color: Color(0xFF010440)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => DisclosureWrapper()),
                (route) => false,
              );
            },
          ),

          //   IconButton(
          //     icon: const Icon(Icons.logout, color: Colors.white),
          //     tooltip: 'Logout',
          //     onPressed: () async {
          //       if (widget.isDriver) {
          //         // For drivers: just navigate to GetStartedPage
          //         Navigator.pushAndRemoveUntil(
          //           context,
          //           MaterialPageRoute(builder: (_) => const GetStartedPage()),
          //           (route) => false,
          //         );
          //       } else {
          //         // For customers: call logout API
          //         final phoneNumber = widget.phoneNumber;
          //
          //         try {
          //           final response = await http.delete(
          //             Uri.parse(
          //               "${AppConfig.localBaseUrl}/api/deleteUser/$phoneNumber",
          //             ),
          //             headers: {"Content-Type": "application/json"},
          //           );
          //
          //           if (response.statusCode == 200) {
          //             final jsonResponse = jsonDecode(response.body);
          //             final message =
          //                 jsonResponse['status']['message'] ??
          //                 "Logout successful.";
          //
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               SnackBar(
          //                 content: Text(message),
          //                 backgroundColor: Colors.green,
          //               ),
          //             );
          //
          //             final prefs = await SharedPreferences.getInstance();
          //             await prefs.clear();
          //
          //             Navigator.pushAndRemoveUntil(
          //               context,
          //               MaterialPageRoute(builder: (_) => const GetStartedPage()),
          //               (route) => false,
          //             );
          //           } else {
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               SnackBar(
          //                 content: Text("Logout failed: ${response.statusCode}"),
          //                 backgroundColor: Colors.red,
          //               ),
          //             );
          //           }
          //         } catch (e) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             SnackBar(
          //               content: Text("Network error: $e"),
          //               backgroundColor: Colors.red,
          //             ),
          //           );
          //         }
          //       }
          //     },
          //   ),
        ],
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF010440),
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),

              child: Row(
                children: List.generate(localizedNavItems.length, (index) {
                  final item = localizedNavItems[index];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (item.icon as Icon).icon,
                            color: isSelected ? Color(0xFFF15F28) : Colors.grey,
                            size: 25,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label!,
                            style: TextStyle(
                              color: isSelected
                                  ? Color(0xFFF15F28)
                                  : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 10),
                            height: 3,
                            width: isSelected ? 16 : 0,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF15F28),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
