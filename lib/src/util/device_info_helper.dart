import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

enum DeviceType { phone, tablet, unknown }

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final Map<String, dynamic> info = {
      'osName': Platform.isAndroid ? 'Android' : 'iOS',
      'osVersion': '',
      'deviceManufacturer': '',
      'deviceModel': '',
      'deviceName': '',
      'deviceType': DeviceType.unknown.name,
    };

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      info['deviceManufacturer'] = androidInfo.manufacturer;
      info['deviceModel'] = androidInfo.model;
      info['deviceName'] = androidInfo.name;
      info['osVersion'] = androidInfo.version.release;
      info['deviceType'] = "Android";
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      info['deviceManufacturer'] = 'Apple';
      info['deviceModel'] = iosInfo.modelName;
      info['deviceName'] = iosInfo.name;
      info['osVersion'] = iosInfo.systemVersion;
      info['deviceType'] = "iOS";
    }

    return info;
  }
}
