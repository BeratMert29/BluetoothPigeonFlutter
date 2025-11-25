/// BLE Constants for the chat application
class BleConstants {
  BleConstants._();

  /// Service UUID for BLE Chat
  static const String serviceUuid = '12345678-1234-1234-1234-123456789abc';

  /// Characteristic UUID for messages
  static const String charMessageUuid = 'abcdefab-1234-5678-1234-abcdefabcdef';

  /// Device name for advertising
  static const String deviceName = 'BLE_CHAT_SERVER';

  /// Maximum MTU size
  static const int maxMtu = 512;
}

