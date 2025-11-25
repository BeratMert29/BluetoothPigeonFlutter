import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble/ble_client_controller.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_input.dart';

/// Chat screen for Client mode (Phone B - Central)
class ClientChatScreen extends StatefulWidget {
  const ClientChatScreen({super.key});

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  late BleClientController _controller;
  final TextEditingController _nameController = TextEditingController(text: 'Client');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = BleClientController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.disconnect();
    _controller.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusBar(),
          if (!_controller.isConnected) ...[
            _buildControlPanel(),
            Expanded(child: _buildDeviceList()),
          ] else ...[
            Expanded(child: _buildMessageList()),
            MessageInput(
              onSend: (text) {
                _controller.sendMessage(text);
              },
              enabled: _controller.isConnected,
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF94), Color(0xFF00CC76)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Color(0xFF0D1117),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _controller.isConnected
                    ? 'Connected to ${_controller.connectedDevice?.platformName ?? "Server"}'
                    : 'BLE Central',
                style: const TextStyle(
                  color: Color(0xFF00FF94),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_controller.isConnected)
          IconButton(
            icon: const Icon(Icons.link_off, color: Color(0xFFFF453A)),
            onPressed: () => _controller.disconnect(),
          ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _controller.isConnected
                  ? const Color(0xFF00FF94)
                  : (_controller.isScanning
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFFFF453A)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller.status,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Name input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Your name',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              onChanged: (value) {
                _controller.setDeviceName(value.isEmpty ? 'Client' : value);
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Scan buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  label: _controller.isScanning ? 'Stop Scan' : 'Scan Services',
                  icon: _controller.isScanning ? Icons.stop : Icons.bluetooth_searching,
                  color: _controller.isScanning
                      ? const Color(0xFFFF453A)
                      : const Color(0xFF00D9FF),
                  onPressed: () async {
                    if (_controller.isScanning) {
                      await _controller.stopScan();
                    } else {
                      await _controller.startScan();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  label: 'Scan All',
                  icon: Icons.search,
                  color: const Color(0xFF00FF94),
                  onPressed: _controller.isScanning
                      ? null
                      : () async {
                          await _controller.startScanAll();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final devices = _controller.scanResults;
    
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _controller.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              _controller.isScanning ? 'Scanning...' : 'No devices found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the server is advertising',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final result = devices[index];
        return _buildDeviceCard(result);
      },
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final name = result.advertisementData.advName.isNotEmpty
        ? result.advertisementData.advName
        : device.platformName.isNotEmpty
            ? device.platformName
            : 'Unknown Device';
    final rssi = result.rssi;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF94).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _connectToDevice(device),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    color: Color(0xFF00FF94),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.remoteId.str,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          color: _getRssiColor(rssi),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rssi dBm',
                          style: TextStyle(
                            color: _getRssiColor(rssi),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return const Color(0xFF00FF94);
    if (rssi >= -70) return const Color(0xFFFFD60A);
    return const Color(0xFFFF453A);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final success = await _controller.connectToServer(device);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${_controller.status}'),
          backgroundColor: const Color(0xFFFF453A),
        ),
      );
    }
  }

  Widget _buildMessageList() {
    final messages = _controller.messages;
    
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Connected!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start typing to send a message',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ChatBubble(
          message: message,
          isMe: message.isSent,
        );
      },
    );
  }
}

