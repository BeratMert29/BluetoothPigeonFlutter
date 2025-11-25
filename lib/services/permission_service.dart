import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service to handle BLE-related permissions
class PermissionService {
  /// Request all necessary BLE permissions
  static Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true; // Permissions not needed on other platforms
    }

    try {
      // Check if Bluetooth is available and on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        // Try to turn on Bluetooth (Android only)
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        }
      }

      if (Platform.isAndroid) {
        // Android 12+ requires these permissions
        final permissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.location,
        ];

        Map<Permission, PermissionStatus> statuses = await permissions.request();
        
        // Check if all permissions are granted
        bool allGranted = true;
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            debugPrint('Permission $permission not granted: $status');
            allGranted = false;
          }
        });

        return allGranted;
      } else if (Platform.isIOS) {
        // iOS handles Bluetooth permissions automatically
        final status = await Permission.bluetooth.request();
        return status.isGranted;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if all BLE permissions are granted
  static Future<bool> checkBlePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        final advertiseStatus = await Permission.bluetoothAdvertise.status;
        
        return scanStatus.isGranted && 
               connectStatus.isGranted && 
               advertiseStatus.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        return status.isGranted;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  static Future<bool> isBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Open app settings for permission management
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

