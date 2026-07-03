// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:convert';
//
// class ApiService {
//   static final storage = FlutterSecureStorage();
//
//   static const String clientId = 'foodswingdev';
//   static const String tokenUrl =
//       'http://fsx-prod-alb-auth-305369466.us-east-1.elb.amazonaws.com/realms/food-swing-dev/protocol/openid-connect/token';
//
//   // 🔹 Get access token from storage
//   static Future<String?> _getToken() async {
//     return await storage.read(key: 'access_token');
//   }
//
//   // 🔹 Refresh token
//   static Future<bool> refreshToken() async {
//     final refreshToken = await storage.read(key: 'refresh_token');
//     if (refreshToken == null) return false;
//
//     final response = await http.post(
//       Uri.parse(tokenUrl),
//       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       body: {
//         'grant_type': 'refresh_token',
//         'client_id': clientId,
//         'refresh_token': refreshToken,
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final tokens = json.decode(response.body);
//       await storage.write(key: 'access_token', value: tokens['access_token']);
//       await storage.write(key: 'refresh_token', value: tokens['refresh_token']);
//       await storage.write(key: 'id_token', value: tokens['id_token']);
//       return true;
//     }
//     return false;
//   }
//
//   // 🔹 Helper to handle 401
//   static Future<http.Response> _retryOn401(
//     Future<http.Response> Function() requestFunc,
//   ) async {
//     var response = await requestFunc();
//     if (response.statusCode == 401) {
//       final refreshed = await refreshToken();
//       if (refreshed) {
//         response = await requestFunc(); // retry
//       }
//     }
//     return response;
//   }
//
//   // 🔹 GET request
//   static Future<http.Response> get(String url) async {
//     return _retryOn401(() async {
//       final token = await _getToken();
//       final headers = {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };
//       return await http.get(Uri.parse(url), headers: headers);
//     });
//   }
//
//   // 🔹 POST request
//   static Future<http.Response> post(
//     String url,
//     Map<String, dynamic> body,
//   ) async {
//     return _retryOn401(() async {
//       final token = await _getToken();
//       final headers = {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };
//       return await http.post(
//         Uri.parse(url),
//         headers: headers,
//         body: json.encode(body),
//       );
//     });
//   }
//
//   static Future<http.Response> put(
//     String url,
//     dynamic body, // Accept List<Map> or Map
//   ) async {
//     return _retryOn401(() async {
//       final token = await _getToken();
//       final headers = {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };
//       return await http.put(
//         Uri.parse(url),
//         headers: headers,
//         body: json.encode(body), // works with Map or List
//       );
//     });
//   }
//
//   // 🔹 DELETE request
//   static Future<http.Response> delete(String url) async {
//     return _retryOn401(() async {
//       final token = await _getToken();
//       final headers = {
//         'Content-Type': 'application/json',
//         if (token != null) 'Authorization': 'Bearer $token',
//       };
//       return await http.delete(Uri.parse(url), headers: headers);
//     });
//   }
// }
