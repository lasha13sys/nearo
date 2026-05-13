import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_config.dart';

class ProximityService {
  final NetworkInfo _networkInfo;

  ProximityService({NetworkInfo? networkInfo}) : _networkInfo = networkInfo ?? NetworkInfo();

  Future<String?> getCurrentWifiHash() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) return null;

    final bssid = await _networkInfo.getWifiBSSID();
    if (bssid == null || bssid.isEmpty) return null;
    return hashBssid(bssid);
  }

  String hashBssid(String bssid) {
    final normalized = bssid.trim().toLowerCase();
    final input = utf8.encode('$normalized:${AppConfig.proximityHashSalt}');
    return sha256.convert(input).toString();
  }
}
