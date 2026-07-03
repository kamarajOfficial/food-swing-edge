// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:jwt_decode/jwt_decode.dart';
// import 'package:foodswing/main.dart';
// import 'config_loader.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// final storage = FlutterSecureStorage();
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await AppConfig.loadConfig();
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sauceit',
//       theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'OpenSans'),
//       home: const KeycloakWebLoginPage(),
//     );
//   }
// }
//
// class KeycloakWebLoginPage extends StatefulWidget {
//   const KeycloakWebLoginPage({super.key});
//
//   @override
//   State<KeycloakWebLoginPage> createState() => _KeycloakWebLoginPageState();
// }
//
// class _KeycloakWebLoginPageState extends State<KeycloakWebLoginPage> {
//   final String loginUrl =
//       'http://fsx-prod-alb-auth-305369466.us-east-1.elb.amazonaws.com/realms/food-swing-dev/protocol/openid-connect/auth?client_id=foodswingdev&redirect_uri=http%3A%2F%2Ffsx.foodswing.in%2F&state=0d9c52b3-4f49-4fa9-a4c8-f4ae6cf6b30d&response_mode=fragment&response_type=code&scope=openid&nonce=71ac9fb5-32fd-4cf8-aba0-681e71931f69';
//
//   late final WebViewController _controller;
//
//   final String tokenUrl =
//       'http://fsx-prod-alb-auth-305369466.us-east-1.elb.amazonaws.com/realms/food-swing-dev/protocol/openid-connect/token';
//   final String clientId = 'foodswingdev';
//   final String redirectUri = 'http://fsx.foodswing.in/';
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onNavigationRequest: (request) async {
//                 if (request.url.startsWith(redirectUri)) {
//                   final uri = Uri.parse(request.url);
//                   final fragment = uri.fragment; // e.g. "code=abc123&state=xyz"
//                   final code = Uri.splitQueryString(fragment)['code'];
//
//                   print('Authorization code: $code');
//
//                   if (code != null) {
//                     // Exchange code for tokens
//                     final tokenResponse = await http.post(
//                       Uri.parse(tokenUrl),
//                       headers: {
//                         'Content-Type': 'application/x-www-form-urlencoded',
//                       },
//                       body: {
//                         'grant_type': 'authorization_code',
//                         'client_id': clientId,
//                         'code': code,
//                         'redirect_uri': redirectUri,
//                       },
//                     );
//
//                     if (tokenResponse.statusCode == 200) {
//                       final tokens = json.decode(tokenResponse.body);
//                       final accessToken = tokens['access_token'];
//                       final idToken = tokens['id_token'];
//
//                       // Decode JWT
//                       Map<String, dynamic> payload = Jwt.parseJwt(idToken);
//                       final preferredUsername = payload['preferred_username'];
//
//                       // Decode access token
//                       Map<String, dynamic> accessPayload = Jwt.parseJwt(
//                         accessToken,
//                       );
//                       await storage.write(key: 'access_token', value: accessToken);
//                       await storage.write(key: 'id_token', value: idToken);
//                       await storage.write(key: 'refresh_token', value: tokens['refresh_token']);
//
//                       // Extract realm roles
//                       List<String> userRoles = [];
//                       if (accessPayload.containsKey('realm_access') &&
//                           accessPayload['realm_access'] != null &&
//                           accessPayload['realm_access']['roles'] != null) {
//                         userRoles = List<String>.from(
//                           accessPayload['realm_access']['roles'],
//                         );
//                       }
//
//                       // Optionally, extract client roles
//                       if (accessPayload.containsKey('resource_access') &&
//                           accessPayload['resource_access'][clientId] != null &&
//                           accessPayload['resource_access'][clientId]['roles'] !=
//                               null) {
//                         userRoles.addAll(
//                           List<String>.from(
//                             accessPayload['resource_access'][clientId]['roles'],
//                           ),
//                         );
//                       }
//
//                       print('Logged in user roles:');
//                       for (var role in userRoles) {
//                         print(role);
//                       }
//
//                       // Extract MobileCompanyId
//                       String companyId = '';
//                       if (payload.containsKey('MobileCompanyId')) {
//                         companyId = payload['MobileCompanyId'].toString();
//                         print('CompanyId: $companyId');
//                       }
//
//                       String SubCustomerId = '';
//                       if (payload.containsKey('SubCustomerId')) {
//                         companyId = payload['SubCustomerId'].toString();
//                         print('SubCustomerId: $SubCustomerId');
//                       }
//
//                       // Extract DriverId from Keycloak attributes
//                       String driverId = '';
//                       if (payload.containsKey('DriverId')) {
//                         driverId = payload['DriverId'].toString();
//                         print('DriverId: $driverId');
//                       }
//
//                       // Navigate to MainTabPage with username and companyId
//                       if (mounted) {
//                         // Split if multiple company IDs
//                         List<String> companyList = [];
//                         if (companyId.contains(',')) {
//                           companyList =
//                               companyId
//                                   .split(',')
//                                   .map((e) => e.trim())
//                                   .toList();
//                         } else if (companyId.isNotEmpty) {
//                           companyList = [companyId];
//                         }
//                         if (mounted) {
//                           // Split if multiple company IDs
//                           List<String> companyList = [];
//                           if (companyId.contains(',')) {
//                             companyList =
//                                 companyId
//                                     .split(',')
//                                     .map((e) => e.trim())
//                                     .toList();
//                           } else if (companyId.isNotEmpty) {
//                             companyList = [companyId];
//                           }
//
//                           // Normalize roles for easier checking
//                           final normalizedRoles =
//                               userRoles
//                                   .map((r) => r.replaceFirst('ROLE_', ''))
//                                   .toList();
//
//                           // 👉 Skip company selection for MOBILE_DRIVER
//                           if (normalizedRoles.contains('MOBILE_DRIVER')) {
//                             final selectedCompanyId =
//                                 companyList.isNotEmpty ? companyList.first : '';
//                             final selectedCompanyName =
//                                 ''; // you can fetch or leave empty
//
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => MainTabPage(
//                                   username: preferredUsername,
//                                   companyId: selectedCompanyId,
//                                   companyName: selectedCompanyName,
//                                   roles: userRoles,
//                                   driverId: driverId, // ✅ pass driverId
//                                 ),
//                               ),
//                             );
//                           } else {
//                             // Default flow → show company dropdown
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder:
//                                     (_) => StalinAnimationScreen(
//                                       username: preferredUsername,
//                                       companies: companyList,
//                                       role: userRoles.join(','),
//                                     ),
//                               ),
//                             );
//                           }
//                         }
//                       }
//                     } else {
//                       print('Token exchange failed: ${tokenResponse.body}');
//                     }
//                   }
//
//                   return NavigationDecision.prevent;
//                 }
//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(loginUrl));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(body: WebViewWidget(controller: _controller));
//   }
// }
//
// class KeycloakWebLoginPageAfterLogout extends StatefulWidget {
//   final String logoutUrl;
//
//   const KeycloakWebLoginPageAfterLogout({super.key, required this.logoutUrl});
//
//   @override
//   State<KeycloakWebLoginPageAfterLogout> createState() =>
//       _KeycloakWebLoginPageAfterLogoutState();
// }
//
// class _KeycloakWebLoginPageAfterLogoutState
//     extends State<KeycloakWebLoginPageAfterLogout> {
//   late final WebViewController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageFinished: (url) async {
//                 print('Navigated to $url');
//
//                 // If we are on Keycloak logout URL, assume logout is done
//                 if (url.contains('/protocol/openid-connect/logout')) {
//                   // Short delay to show the logout page briefly
//                   await Future.delayed(const Duration(seconds: 3));
//
//                   // Navigate back to login page
//                   if (mounted) {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const KeycloakWebLoginPage(),
//                       ),
//                     );
//                   }
//                 }
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.logoutUrl));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Logging out...')),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
