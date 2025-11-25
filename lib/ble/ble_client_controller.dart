import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/chat_message.dart';
import 'ble_constants.dart';

/// Controller for BLE Central/Client (Phone B)
class BleClientController extends ChangeNotifier {
  bool _isScanning = false;
  bool _isConnected = false;
  String _status = 'Idle';
  final List<ChatMessage> _messages = [];
  final List<ScanResult> _scanResults = [];
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _messageCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;
  String _deviceName = 'Client';

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get status => _status;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get deviceName => _deviceName;

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  /// Start scanning for BLE devices
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _scanResults.clear();
      _status = 'Scanning...';
      _isScanning = true;
      notifyListeners();

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        for (var result in results) {
          // Filter by service UUID if available
          final hasTargetService = result.advertisementData.serviceUuids.any(
            (uuid) => uuid.toString().toLowerCase() == BleConstants.serviceUuid.toLowerCase(),
          );
          
          // Also include devices with the expected name or with our service
          if (hasTargetService || 
              result.advertisementData.advName.contains('BLE') ||
              result.advertisementData.advName.contains('Chat')) {
            _scanResults.add(result);
          }
        }
        notifyListeners();
      });

      // Start scanning with service filter
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(BleConstants.serviceUuid)],
      );

      // When scan completes
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      _isScanning = false;
      _status = 'Scan complete. Found ${_scanResults.length} device(s)';
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      _status = 'Scan error: $e';
      notifyListeners();
    }
  }

  /// Start scanning without service filter (finds all BLE devices)
  Future<void> startScanAll() async {
    if (_isScanning) return;

    try {
      _scanResults.clear();
      _status = 'Scanning all devices...';
      _isScanning = true;
      notifyListeners();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        _scanResults.addAll(results.where((r) => r.advertisementData.advName.isNotEmpty));
        notifyListeners();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      _isScanning = false;
      _status = 'Scan complete. Found ${_scanResults.length} device(s)';
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      _status = 'Scan error: $e';
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      _status = 'Scan stopped';
      notifyListeners();
    } catch (e) {
      _status = 'Stop scan error: $e';
      notifyListeners();
    }
  }

  /// Connect to a BLE server
  Future<bool> connectToServer(BluetoothDevice device) async {
    try {
      _status = 'Connecting to ${device.platformName}...';
      notifyListeners();

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Request higher MTU for larger messages
      await device.requestMtu(BleConstants.maxMtu);

      // Discover services
      _status = 'Discovering services...';
      notifyListeners();
      
      final services = await device.discoverServices();
      
      // Find our chat service
      BluetoothService? chatService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == BleConstants.serviceUuid.toLowerCase()) {
          chatService = service;
          break;
        }
      }

      if (chatService == null) {
        _status = 'Chat service not found';
        await disconnect();
        return false;
      }

      // Find message characteristic
      for (var characteristic in chatService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == BleConstants.charMessageUuid.toLowerCase()) {
          _messageCharacteristic = characteristic;
          break;
        }
      }

      if (_messageCharacteristic == null) {
        _status = 'Message characteristic not found';
        await disconnect();
        return false;
      }

      // Enable notifications
      await _messageCharacteristic!.setNotifyValue(true);
      
      // Listen for incoming messages
      _characteristicSubscription = _messageCharacteristic!.onValueReceived.listen((value) {
        _handleIncomingMessage(value);
      });

      _isConnected = true;
      _status = 'Connected to ${device.platformName}';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Connection error: $e';
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void _handleIncomingMessage(List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      final message = ChatMessage.fromJsonString(jsonString, isSent: false);
      _messages.add(message);
      _status = 'Message received';
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing incoming message: $e');
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _connectedDevice = null;
    _messageCharacteristic = null;
    _characteristicSubscription?.cancel();
    _status = 'Disconnected';
    notifyListeners();
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    try {
      _characteristicSubscription?.cancel();
      _connectionSubscription?.cancel();
      await _connectedDevice?.disconnect();
      _handleDisconnection();
    } catch (e) {
      _status = 'Disconnect error: $e';
      notifyListeners();
    }
  }

  /// Send a message to the server
  Future<bool> sendMessage(String text) async {
    if (text.isEmpty || _messageCharacteristic == null) return false;

    try {
      final message = ChatMessage.text(
        from: _deviceName,
        message: text,
        isSent: true,
      );

      final bytes = utf8.encode(message.toJsonString());
      
      await _messageCharacteristic!.write(bytes, withoutResponse: false);
      
      _messages.add(message);
      _status = 'Message sent';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Send error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Listen for messages (re-enable notifications if needed)
  Future<void> listenMessages() async {
    if (_messageCharacteristic == null) return;

    try {
      await _messageCharacteristic!.setNotifyValue(true);
      _status = 'Listening for messages...';
      notifyListeners();
    } catch (e) {
      _status = 'Listen error: $e';
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.dispose();
  }
}

