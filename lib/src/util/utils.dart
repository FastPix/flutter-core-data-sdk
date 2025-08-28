import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class Utils {
  static final Uuid _uuid = Uuid();

  static String getVideoTypeFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return "Unknown";

    final segments = uri.pathSegments;
    if (segments.isEmpty) return "Unknown";

    final lastSegment = segments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) {
      return "Unknown";
    }

    final extension = lastSegment.substring(dotIndex + 1).toLowerCase();
    return extension;
  }

  static Future<String?> checkNetworkType() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return "cellular";
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return "wifi";
    } else {
      return null;
    }
  }

  static String? getDomain(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    final uri = Uri.parse(url);
    return uri.host;
  }

  static String generateUuid() {
    return _uuid.v4();
  }
}
