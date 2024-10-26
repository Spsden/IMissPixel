import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionUtils {
  static Future<bool> requestPermissions() async {
    List<Permission> permissions = _getRequiredPermissions();

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    bool allGranted = true;

    final androidVersion = await _getAndroidVersion();
    bool isSdk33AndAbove = androidVersion.version.sdkInt >= 33;

    for (var entry in statuses.entries) {
      if (isSdk33AndAbove && entry.key == Permission.storage) continue;

      if (!entry.value.isGranted) {
        allGranted = false;
        print('Permission ${entry.key} is ${entry.value}');
      }
    }

    return allGranted;
  }

  static Future<bool> checkPermissions() async {
    List<Permission> permissions = _getRequiredPermissions();

    final androidVersion = await _getAndroidVersion();
    bool isSdk33AndAbove = androidVersion.version.sdkInt >= 33;

    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in permissions) {
      if (isSdk33AndAbove && permission == Permission.storage) continue;
      statuses[permission] = await permission.status;
    }

    return statuses.values.every((status) => status.isGranted);
  }

  static List<Permission> _getRequiredPermissions() {
    List<Permission> permissions = [Permission.storage];

    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.manageExternalStorage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ]);
    }

    permissions.add(Permission.location);
    return permissions;
  }

  static Future<AndroidDeviceInfo> _getAndroidVersion() async {
    final plugin = DeviceInfoPlugin();
    return await plugin.androidInfo;
  }
}
