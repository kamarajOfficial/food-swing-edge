// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:foodswing/QrCodeScreen.dart';
// import 'package:foodswing/ViewEditOrders.dart';
// import 'package:foodswing/homePage.dart';
// import 'package:foodswing/profile.dart';
// import 'dart:convert';
// import 'package:foodswing/orderPage.dart';
// import 'package:foodswing/tripPage.dart';
// import 'package:jwt_decode/jwt_decode.dart';
// import 'DriverHomePage.dart';
// import 'config_loader.dart';
// import 'loginPage.dart';
// import 'trackPage.dart';
// import 'menuPage.dart';
// import 'package:foodswing/api_service.dart';
//
// // ----------------- Main Tab Page -----------------
// class MainTabPage extends StatefulWidget {
//   final String username;
//   final String companyId;
//   final String companyName;
//   final List<String> roles;
//   final String? driverId;
//   final String? subCustomerId;
//
//   const MainTabPage({
//     super.key,
//     required this.username,
//     required this.companyId,
//     required this.companyName,
//     required this.roles,
//     this.driverId,
//     this.subCustomerId,
//   });
//
//   @override
//   State<MainTabPage> createState() => _MainTabPageState();
// }
//
// class _MainTabPageState extends State<MainTabPage> {
//   final String logoutUrl =
//       'http://fsx-prod-alb-auth-305369466.us-east-1.elb.amazonaws.com/realms/food-swing-dev/protocol/openid-connect/logout';
//
//   int _selectedIndex = 0;
//
//   late List<Widget> _pages;
//   late List<BottomNavigationBarItem> _navItems;
//   Map<String, dynamic>? _driverDetails;
//
//   String? _displayName;
//
//   @override
//   void initState() {
//     super.initState();
//     _displayName = widget.username;
//     _buildPages();
//
//     final normalizedRoles =
//         widget.roles.map((r) => r.replaceFirst('ROLE_', '')).toList();
//
//     if (normalizedRoles.contains('MOBILE_DRIVER') &&
//         widget.driverId != null &&
//         widget.driverId!.isNotEmpty) {
//       _fetchDriverName(widget.driverId!);
//     }
//   }
//
//   void _buildPages() {
//     final normalizedRoles =
//         widget.roles.map((r) => r.replaceFirst('ROLE_', '')).toList();
//
//     if (normalizedRoles.contains('MOBILE_DRIVER') &&
//         widget.driverId != null &&
//         widget.driverId!.isNotEmpty) {
//       _fetchDriverName(widget.driverId!);
//     }
//
//     if (normalizedRoles.contains('MOBILE_CUSTOMER')) {
//       _pages = [
//         HomePage(companyId: widget.companyId),
//         OrdersPage(
//           username: widget.username,
//           companyId: widget.companyId,
//           companyName: widget.companyName,
//           role: widget.roles.join(','),
//           subCustomerId: widget.subCustomerId,
//         ),
//         SelectOrderDateScreen(
//           companyId: widget.companyId,
//           subCustomerId: widget.subCustomerId,
//         ),
//         TrackOrderPage(companyId: widget.companyId),
//         MenuPage(companyId: widget.companyId),
//       ];
//
//       _navItems = const [
//         BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.shopping_cart),
//           label: 'Indent',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.mode_edit_outline_rounded),
//           label: 'Edit Indent',
//         ),
//         BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Track'),
//         BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
//       ];
//     } else if (normalizedRoles.contains('MOBILE_DRIVER')) {
//       _pages = [
//         DriverHomePage(driverId: widget.driverId.toString()),
//         TripListPage(driverId: widget.driverId.toString()),
//         // Center(child: Text('QR Code', style: TextStyle(fontSize: 24))),
//         QrCodeScreen(username: _displayName ?? widget.username),
//         EditProfilePage(
//           username: _displayName ?? widget.username,
//           driverDetails: _driverDetails,
//         ),
//       ];
//
//       _navItems = const [
//         BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.location_on_rounded),
//           label: 'Trip',
//         ),
//         BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'QR'),
//         BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//       ];
//     } else {
//       // fallback default
//       _pages = [
//         Center(child: Text('Home Page', style: TextStyle(fontSize: 24))),
//         Center(child: Text('Order Page', style: TextStyle(fontSize: 24))),
//         Center(child: Text('Edit Order Page', style: TextStyle(fontSize: 24))),
//         Center(child: Text('Track Page', style: TextStyle(fontSize: 24))),
//         Center(child: Text('Menu Page', style: TextStyle(fontSize: 24))),
//       ];
//
//       _navItems = const [
//         BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.shopping_cart),
//           label: 'Order',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.mode_edit_outline_rounded),
//           label: 'Edit Orders',
//         ),
//         BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Track'),
//         BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
//       ];
//     }
//   }
//
//   Future<void> _fetchDriverName(String driverId) async {
//     try {
//       final response = await ApiService.get(
//         '${AppConfig.localBaseUrl}/api/getMobileDriverById/$driverId',
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final driverData = data['data'];
//
//         if (driverData != null && driverData['fullName'] != null) {
//           setState(() {
//             _displayName = driverData['fullName'];
//
//             // ✅ Store additional driver info
//             _driverDetails = {
//               'mobileNumber': driverData['mobileNumber'] ?? '',
//               'address': driverData['address'] ?? '',
//               'dateOfBirth': driverData['dateOfBirth'] ?? '',
//               'bloodGroup': driverData['bloodGroup'] ?? '',
//             };
//
//             _buildPages(); // rebuild pages to update EditProfilePage
//           });
//         }
//       } else {
//         print('Failed to fetch driver details: ${response.body}');
//       }
//     } catch (e) {
//       print('Error fetching driver details: $e');
//     }
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF010440),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'HELLO ${(_displayName ?? widget.username).toString().toUpperCase()},',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               widget.companyName,
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.support_agent_sharp, color: Colors.white),
//             tooltip: 'Support',
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return AlertDialog(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     title: const Text(
//                       'For more enquiries',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.support_agent_rounded,
//                           color: Colors.indigoAccent,
//                           size: 48,
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Customer Support',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               '+91 73050 46337',
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 color: Color(0xFFF15F28),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             IconButton(
//                               icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
//                               tooltip: 'Copy number',
//                               onPressed: () {
//                                 Clipboard.setData(
//                                     const ClipboardData(text: '+917305046337'));
//                                 // ScaffoldMessenger.of(context).showSnackBar(
//                                 //   const SnackBar(
//                                 //     content: Text(''),
//                                 //     duration: Duration(seconds: 2),
//                                 //   ),
//                                 // );
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     actions: [
//                       TextButton(
//                         child: const Text(
//                           'CLOSE',
//                           style: TextStyle(color: const Color(0xFF010440)),
//                         ),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//           // 🔒 Logout icon
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             tooltip: 'Logout',
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (_) => KeycloakWebLoginPageAfterLogout(
//                         logoutUrl:
//                             'http://fsx-prod-alb-auth-305369466.us-east-1.elb.amazonaws.com/realms/food-swing-dev/protocol/openid-connect/logout',
//                       ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//
//       // 🟢 Page Content
//       body: _pages[_selectedIndex],
//
//       // 🔵 Modern Bottom Navigation Bar
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: const BoxDecoration(
//           color: const Color(0xFF010440), // dark background
//           borderRadius: BorderRadius.all(Radius.circular(24)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black38,
//               blurRadius: 10,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: List.generate(_navItems.length, (index) {
//                 final item = _navItems[index];
//                 final bool isSelected = _selectedIndex == index;
//
//                 return GestureDetector(
//                   onTap: () => _onItemTapped(index),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         (item.icon as Icon).icon,
//                         color:
//                             isSelected ? Colors.deepOrangeAccent : Colors.grey,
//                         size: 25,
//                       ),
//
//                       const SizedBox(height: 4),
//                       Text(
//                         item.label!,
//                         style: TextStyle(
//                           color:
//                               isSelected
//                                   ? Colors.deepOrangeAccent
//                                   : Colors.grey,
//                           fontWeight:
//                               isSelected ? FontWeight.bold : FontWeight.normal,
//                           fontSize: 10,
//                         ),
//                       ),
//                       const SizedBox(height: 3),
//                       AnimatedContainer(
//                         duration: const Duration(milliseconds: 10),
//                         height: 3,
//                         width: isSelected ? 12 : 0,
//                         decoration: BoxDecoration(
//                           color: Colors.deepOrangeAccent,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CompanySelectionPage extends StatefulWidget {
//   final String username;
//   final List<String> companies; // List of company IDs from token
//   final String role;
//
//   const CompanySelectionPage({
//     super.key,
//     required this.username,
//     required this.companies,
//     required this.role,
//   });
//
//   @override
//   State<CompanySelectionPage> createState() => _CompanySelectionPageState();
// }
//
// class _CompanySelectionPageState extends State<CompanySelectionPage> {
//   String? _selectedCompanyId;
//   Map<String, String> _companyMap = {}; // id → name
//   bool _loading = true;
//   Map<String, Map<String, String>> _mappedCompanyDetails = {};
//
//   bool isSubCustomer = false; // 🟡 Track which API to call
//
//   @override
//   void initState() {
//     super.initState();
//     _detectCompanyTypeAndFetch();
//   }
//
//   /// 🔍 Determine which attribute was used (MobileCompanyId / SubCustomerId)
//   Future<void> _detectCompanyTypeAndFetch() async {
//     try {
//       // Retrieve the stored ID token
//       final idToken = await storage.read(key: 'id_token');
//       if (idToken != null) {
//         final payload = Jwt.parseJwt(idToken);
//
//         if (payload.containsKey('SubCustomerId')) {
//           isSubCustomer = true;
//           print("🟢 Logged in with SubCustomerId");
//         } else if (payload.containsKey('MobileCompanyId')) {
//           isSubCustomer = false;
//           print("🟢 Logged in with MobileCompanyId");
//         }
//       }
//       _fetchCompanyNames();
//     } catch (e) {
//       print("Error detecting ID type: $e");
//       _fetchCompanyNames();
//     }
//   }
//
//   /// 🧩 Fetch either company or sub-customer list
//   Future<void> _fetchCompanyNames() async {
//     final String apiUrl =
//         isSubCustomer
//             ? '${AppConfig.localBaseUrl}/api/getSubCustomerMasterMobile'
//             : '${AppConfig.localBaseUrl}/api/companyAllGetList/list';
//
//     print("🔍 Fetching from: $apiUrl");
//     print("🔍 isSubCustomer: $isSubCustomer");
//
//     try {
//       final response = await ApiService.get(apiUrl);
//       print("📥 Status: ${response.statusCode}");
//       print("📦 Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List list = data['data'] ?? [];
//
//         final Map<String, Map<String, String>> mapped = {};
//         // id → { name, companyId (uomId) }
//
//         for (var item in list) {
//           final idStr = item['id'].toString();
//
//           if (widget.companies.contains(idStr)) {
//             final name = item['name'] ?? 'Unknown';
//             final companyId =
//                 isSubCustomer
//                     ? item['uomId']?.toString() ??
//                         '' // 👈 Use uomId for subcustomer
//                     : item['id'].toString();
//
//             mapped[idStr] = {'name': name, 'companyId': companyId};
//           }
//         }
//
//         setState(() {
//           _companyMap = mapped.map(
//             (key, value) => MapEntry(key, value['name']!),
//           );
//           _mappedCompanyDetails = mapped;
//           _loading = false;
//         });
//
//         // ✅ If only one company, skip selection screen
//         if (_mappedCompanyDetails.length == 1) {
//           final firstKey = _mappedCompanyDetails.keys.first;
//           final selected = _mappedCompanyDetails[firstKey]!;
//
//           // ScaffoldMessenger.of(context).showSnackBar(
//           //   const SnackBar(content: Text("Auto-selecting company...")),
//           // );
//
//           Future.delayed(const Duration(milliseconds: 200), () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder:
//                     (_) => MainTabPage(
//                       username: widget.username,
//                       companyId: selected['companyId']!,
//                       companyName: selected['name']!,
//                       roles: widget.role.split(','),
//                       subCustomerId: isSubCustomer ? firstKey : null,
//                     ),
//               ),
//             );
//           });
//         }
//       } else {
//         throw Exception("Failed to load company list");
//       }
//     } catch (e) {
//       print("❌ API error: $e");
//       setState(() => _loading = false);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error loading list: $e")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue.shade50,
//       body:
//           _loading
//               ? const Center(child: CircularProgressIndicator())
//               : Center(
//                 child: Card(
//                   elevation: 8,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   margin: const EdgeInsets.all(20),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           isSubCustomer
//                               ? "Choose Your Zone"
//                               : "Choose Your Company",
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF010440),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         DropdownButtonFormField<String>(
//                           value: _selectedCompanyId,
//                           decoration: InputDecoration(
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             labelText:
//                                 isSubCustomer
//                                     ? 'Zone Name'
//                                     : 'Company Name',
//                           ),
//                           items:
//                               _companyMap.entries
//                                   .map(
//                                     (e) => DropdownMenuItem(
//                                       value: e.key,
//                                       child: Text(
//                                         e.value,
//                                         style: const TextStyle(fontSize: 12),
//                                       ),
//                                     ),
//                                   )
//                                   .toList(),
//                           onChanged:
//                               (val) => setState(() => _selectedCompanyId = val),
//                         ),
//                         const SizedBox(height: 30),
//                         ElevatedButton.icon(
//                           icon: const Icon(Icons.check_circle_outline),
//                           label: const Text("Continue"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF010440),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 40,
//                               vertical: 14,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           onPressed:
//                               _selectedCompanyId == null
//                                   ? null
//                                   : () {
//                                     final selectedCompanyData =
//                                         _mappedCompanyDetails[_selectedCompanyId] ??
//                                         {};
//                                     final selectedCompanyName =
//                                         selectedCompanyData['name'] ?? '';
//                                     final actualCompanyId =
//                                         selectedCompanyData['companyId'] ??
//                                         _selectedCompanyId!;
//
//                                     Navigator.pushReplacement(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (_) => MainTabPage(
//                                               username: widget.username,
//                                               companyId: actualCompanyId,
//                                               // 👈 use uomId if subcustomer
//                                               companyName: selectedCompanyName,
//                                               roles: widget.role.split(','),
//                                               subCustomerId:
//                                                   isSubCustomer
//                                                       ? _selectedCompanyId!
//                                                       : null,
//                                             ),
//                                       ),
//                                     );
//                                   },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//     );
//   }
// }
//
// class StalinAnimationScreen extends StatefulWidget {
//   final String username;
//   final List<String> companies;
//   final String role;
//
//   const StalinAnimationScreen({
//     super.key,
//     required this.username,
//     required this.companies,
//     required this.role,
//   });
//
//   @override
//   State<StalinAnimationScreen> createState() => _StalinAnimationScreenState();
// }
//
// class _StalinAnimationScreenState extends State<StalinAnimationScreen> {
//   bool _showFirst = true;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // toggle between two images every 1 second
//     Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (!mounted) return;
//       setState(() => _showFirst = !_showFirst);
//     });
//
//     // after 3 seconds, go to CompanySelectionPage
//     Future.delayed(const Duration(seconds: 4), () {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => CompanySelectionPage(
//                   username: widget.username,
//                   companies: widget.companies,
//                   role: widget.role,
//                 ),
//           ),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: AnimatedSwitcher(
//           duration: const Duration(milliseconds: 600),
//           transitionBuilder: (Widget child, Animation<double> animation) {
//             return FadeTransition(opacity: animation, child: child);
//           },
//           child: Image.asset(
//             _showFirst
//                 ? 'assets/images/food treaser.png'
//                 : 'assets/images/stalin treaser.png',
//             key: ValueKey<bool>(_showFirst),
//             width: 400,
//             height: 280,
//             fit: BoxFit.contain,
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'GetStartedPage.dart';
import 'ProminentDisclosurePage.dart';
import 'config_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await AppConfig.loadConfig();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sauceit',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'OpenSans'),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: DisclosureWrapper(),
    );
  }
}

class DisclosureWrapper extends StatefulWidget {
  @override
  State<DisclosureWrapper> createState() => _DisclosureWrapperState();
}

class _DisclosureWrapperState extends State<DisclosureWrapper> {
  @override
  Widget build(BuildContext context) {
    return ProminentDisclosurePage(
      onPermissionGranted: () async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _checkDeviceLogin();
        });
      },
    );
  }

  Future<void> _checkDeviceLogin() async {
    final deviceId = await _getDeviceId();
    final url = "${AppConfig.localBaseUrl}/api/deviceLogin/$deviceId";

    print("🔍 Checking device login: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("📥 Device Login Response (${response.statusCode}): ${response.body}");

      // Decode JSON always (even if status = 200 but message says 404)
      final jsonData = json.decode(response.body);
      final apiStatusCode = jsonData["status"]["code"];
      final message = jsonData["status"]["message"];
      final data = jsonData["data"];

      // 🔥 CHECK API STATUS CODE
      if (apiStatusCode == 404) {
        print("⚠️ No device record found — redirecting to Get Started Page");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GetStartedPage()),
              (route) => false,
        );
        return;
      }

      // 🔥 If API status is 200 => proceed with login cases
      if (apiStatusCode == 200) {
        _handleLoginCases(message, data);
        return;
      }

      // 🔥 Unexpected API status — go to Get Started
      print("❌ Unexpected status — going to Get Started Page");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
            (route) => false,
      );

    } catch (e) {
      print("❌ Error while checking device login: $e");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
            (route) => false,
      );
    }
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

  void _handleLoginCases(String message, dynamic data) {
    if (message == "Phone number belongs to a driver." && data != null) {
      final phoneNumber = data['phoneNumber'].toString();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (_) => MainTabPage(
            username: phoneNumber,
            companyId: '',
            companyName: "Driver",
            subCustomerId: '',
            phoneNumber: phoneNumber,
            loginSessions: const [],
            isDriver: true,
          ),
        ),
            (route) => false, // remove all previous routes
      );
    }

    if (message == "Foodswing user login" && data != null) {
      final loginSessions = data['loginSession'] as List<dynamic>? ?? [];
      final phoneNumber = data['phoneNumber'];

      // Extract company names safely
      final uniqueCompanies = <String, Map<String, String>>{};

      for (var session in loginSessions) {
        final id = session["companyId"].toString();
        final name = session["companyName"].toString();

        // Insert only if not seen already
        uniqueCompanies[id] = {"companyId": id, "companyName": name};
      }

      final companies = uniqueCompanies.values.toList();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => FsAnimationScreen(
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

    if (message == "Customer user login" && data != null) {
      final loginSessions = data['loginSession'] as List<dynamic>?;

      if (loginSessions != null && loginSessions.isNotEmpty) {
        final phoneNumber = data['phoneNumber'];

        // Extract all company names (avoid duplicates)
        final companyNames =
        loginSessions
            .map((s) => s['companyName']?.toString() ?? '')
            .toSet()
            .toList();

        // ✅ Pass the entire loginSession list to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => StalinAnimationScreen(
              username: data['username'].toString(),
              // or any display name
              companies: companyNames,
              companyId: loginSessions.first['companyId'].toString(),
              subCustomerId: '',
              // not needed if multiple
              phoneNumber: phoneNumber,
              loginSessions: loginSessions, // 👈 pass full list
            ),
          ),
        );
        return; // Stop other checks
      }

      /// FALLBACK → No valid login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
            (route) => false,
      );
    }
  }
}

// class DisclosureWrapper extends StatefulWidget {
//   @override
//   State<DisclosureWrapper> createState() => _DisclosureWrapperState();
// }
//
// class _DisclosureWrapperState extends State<DisclosureWrapper> {
//   @override
//   Widget build(BuildContext context) {
//     return ProminentDisclosurePage(
//       onPermissionGranted: () {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => const GetStartedPage()),
//                 (route) => false,
//           );
//         });
//       },
//     );
//   }
// }
