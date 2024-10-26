import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionUtils {
  static Future<bool> requestPermissions() async {
    List<Permission> permissions = [
      Permission.storage,
      if (Platform.isAndroid) ...[
        Permission.manageExternalStorage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ],
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = true;
    for (var entry in statuses.entries) {
      if (!entry.value.isGranted) {
        allGranted = false;
        print('Permission ${entry.key} is ${entry.value}');
      }
    }

    return allGranted;
  }

  static Future<bool> checkPermissions() async {
    List<Permission> permissions = [
      Permission.storage,
      if (Platform.isAndroid) ...[
        Permission.manageExternalStorage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ],
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in permissions) {
      statuses[permission] = await permission.status;
    }

    return statuses.values.every((status) => status.isGranted);
  }
}
