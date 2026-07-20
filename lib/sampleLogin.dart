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

    for (final baseUrl in AppConfig.allBaseUrls) {
      try {
        final response = await http
            .get(Uri.parse("$baseUrl/api/deviceLogin/$deviceId"))
            .timeout(const Duration(seconds: 5));

        final json = jsonDecode(response.body);

        if (json["status"]["code"] == 200) {
          AppConfig.setApiBaseUrl(baseUrl);

          print("Logged in using $baseUrl");

          _handleLoginCases(json["status"]["message"], json["data"]);
          return;
        }
      } catch (_) {}
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedPage()),
      (_) => false,
    );
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
                message == "Foodswing user login", // always true for this case
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
        final companyNames = loginSessions
            .map((s) => s['companyName']?.toString() ?? '')
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
