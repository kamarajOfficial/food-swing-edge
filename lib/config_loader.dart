// import 'package:flutter/services.dart';
// import 'package:yaml/yaml.dart';
//
// class AppConfig {
//   static late Map<dynamic, dynamic> _baseUrls;
//   static late String baseUrl;
//
//   static Future<void> loadConfig() async {
//     final yamlString = await rootBundle.loadString('assets/config.yaml');
//     final yaml = loadYaml(yamlString);
//
//     _baseUrls = yaml['base_urls'];
//
//     // Default URL
//     baseUrl = _baseUrls['development'];
//   }
//
//   static void setBaseUrl(String organization) {
//     switch (organization.toLowerCase()) {
//       case 'fs':
//         baseUrl = _baseUrls['fsx'];
//         break;
//
//       case 'gcc':
//         baseUrl = _baseUrls['gcc'];
//         break;
//
//       case 'janani':
//         baseUrl = _baseUrls['janani'];
//         break;
//
//       case 'development':
//         baseUrl = _baseUrls['local'];
//         break;
//
//       default:
//         baseUrl = _baseUrls['development'];
//     }
//
//     print("Current Base URL: $baseUrl");
//   }
// }

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class AppConfig {
  static late Map<dynamic, dynamic> _baseUrls;

  /// Organization API
  static late String apiBaseUrl;

  /// Local API
  static late String localBaseUrl;

  static Future<void> loadConfig() async {
    final yamlString = await rootBundle.loadString('assets/config.yaml');
    final yaml = loadYaml(yamlString);

    _baseUrls = yaml['base_urls'];

    localBaseUrl = _baseUrls['local'];

    // Default
    apiBaseUrl = localBaseUrl;
  }

  static void setBaseUrl(String organization) {
    switch (organization.toLowerCase()) {
      case "fs":
        apiBaseUrl = _baseUrls["fsx"];
        break;

      case "gcc":
        apiBaseUrl = _baseUrls["gcc"];
        break;

      case "jan":
        apiBaseUrl = _baseUrls["janani"];
        break;

      case "local":
        apiBaseUrl = localBaseUrl;
        break;

      default:
        apiBaseUrl = localBaseUrl;
    }

    print("Organization API : $apiBaseUrl");
    print("Local API        : $localBaseUrl");
  }

  /// Helper methods
  static String local(String endpoint) =>
      "$localBaseUrl$endpoint";

  static String api(String endpoint) =>
      "$apiBaseUrl$endpoint";

  static List<String> get allBaseUrls => [
    localBaseUrl,
    _baseUrls["fsx"],
    _baseUrls["janani"],
    _baseUrls["gcc"],
  ];

  static void setApiBaseUrl(String url) {
    apiBaseUrl = url;
  }
}