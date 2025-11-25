import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';

/// Controller for BLE GATT Server (Phone A - Peripheral)
class BleServerController extends ChangeNotifier {
  static const MethodChannel _methodChannel = MethodChannel('com.example.untitled/ble_server');
  static const EventChannel _eventChannel = EventChannel('com.example.untitled/ble_server_events');

  bool _isServerRunning = false;
  bool _isAdvertising = false;
  String _status = 'Idle';
  final List<ChatMessage> _messages = [];
  final Set<String> _connectedDevices = {};
  StreamSubscription? _eventSubscription;
  String _deviceName = 'Server';

  // Getters
  bool get isServerRunning => _isServerRunning;
  bool get isAdvertising => _isAdvertising;
  String get status => _status;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Set<String> get connectedDevices => Set.unmodifiable(_connectedDevices);
  String get deviceName => _deviceName;

  BleServerController() {
    _initEventListener();
  }

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  void _initEventListener() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          _handleEvent(Map<String, dynamic>.from(event));
        }
      },
      onError: (error) {
        _status = 'Event stream error: $error';
        notifyListeners();
      },
    );
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    
    switch (type) {
      case 'serverStarted':
        _isServerRunning = true;
        _status = 'Server started';
        break;
      case 'serverStopped':
        _isServerRunning = false;
        _isAdvertising = false;
        _connectedDevices.clear();
        _status = 'Server stopped';
        break;
      case 'advertisingStarted':
        _isAdvertising = true;
        _status = 'Advertising...';
        break;
      case 'advertisingStopped':
        _isAdvertising = false;
        _status = 'Advertising stopped';
        break;
      case 'deviceConnected':
        final address = event['address'] as String?;
        if (address != null) {
          _connectedDevices.add(address);
          _status = 'Device connected: $address';
        }
        break;
      case 'deviceDisconnected':
        final address = event['address'] as String?;
        if (address != null) {
          _connectedDevices.remove(address);
          _status = 'Device disconnected: $address';
        }
        break;
      case 'messageReceived':
        final messageJson = event['message'] as String?;
        if (messageJson != null) {
          try {
            final message = ChatMessage.fromJsonString(messageJson, isSent: false);
            _messages.add(message);
            _status = 'Message received';
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        }
        break;
      case 'notificationsChanged':
        final enabled = event['enabled'] as bool? ?? false;
        _status = enabled ? 'Notifications enabled' : 'Notifications disabled';
        break;
      case 'mtuChanged':
        final mtu = event['mtu'] as int?;
        _status = 'MTU changed to $mtu';
        break;
      case 'error':
        final errorMessage = event['message'] as String? ?? 'Unknown error';
        _status = 'Error: $errorMessage';
        break;
    }
    
    notifyListeners();
  }

  /// Start the GATT server
  Future<bool> startServer() async {
    try {
      _status = 'Starting server...';
      notifyListeners();
      
      final result = await _methodChannel.invokeMethod<bool>('startServer');
      return result ?? false;
    } on PlatformException catch (e) {
      _status = 'Failed to start server: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Stop the GATT server
  Future<void> stopServer() async {
    try {
      _status = 'Stopping server...';
      notifyListeners();
      
      await _methodChannel.invokeMethod('stopServer');
    } on PlatformException catch (e) {
      _status = 'Failed to stop server: ${e.message}';
      notifyListeners();
    }
  }

  /// Start advertising
  Future<bool> startAdvertising() async {
    try {
      _status = 'Starting advertising...';
      notifyListeners();
      
      final result = await _methodChannel.invokeMethod<bool>('startAdvertising');
      return result ?? false;
    } on PlatformException catch (e) {
      _status = 'Failed to start advertising: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    try {
      await _methodChannel.invokeMethod('stopAdvertising');
    } on PlatformException catch (e) {
      _status = 'Failed to stop advertising: ${e.message}';
      notifyListeners();
    }
  }

  /// Send a message to connected clients via notification
  Future<bool> sendMessage(String text) async {
    if (text.isEmpty) return false;
    
    try {
      final message = ChatMessage.text(
        from: _deviceName,
        message: text,
        isSent: true,
      );
      
      final result = await _methodChannel.invokeMethod<bool>(
        'sendMessage',
        {'message': message.toJsonString()},
      );
      
      if (result == true) {
        _messages.add(message);
        notifyListeners();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      _status = 'Failed to send message: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

