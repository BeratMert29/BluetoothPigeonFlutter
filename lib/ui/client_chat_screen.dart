import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble/ble_client_controller.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_input.dart';

class ClientChatScreen extends StatefulWidget {
  const ClientChatScreen({super.key});

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  late BleClientController _controller;
  final TextEditingController _nameController =
      TextEditingController(text: 'Client');
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
      backgroundColor: const Color(0xFF09091A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusStrip(),
          if (!_controller.isConnected) ...[
            _buildControlPanel(),
            Expanded(child: _buildDeviceList()),
          ] else ...[
            Expanded(child: _buildMessageList()),
            MessageInput(
              onSend: _controller.sendMessage,
              enabled: _controller.isConnected,
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F1020),
      elevation: 0,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Color(0xFF8B5CF6),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                _controller.isConnected
                    ? _controller.connectedDevice?.platformName ?? 'Connected'
                    : 'BLE Central',
                style: TextStyle(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_controller.isConnected)
          IconButton(
            icon: Icon(
              Icons.link_off_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
            onPressed: _controller.disconnect,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatusStrip() {
    final color = _controller.isConnected
        ? const Color(0xFF22D3A5)
        : _controller.isScanning
            ? const Color(0xFFF59E0B)
            : const Color(0xFFF43F5E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1020),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _controller.status,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12.5,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1020),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Name field
          _buildNameField(
            controller: _nameController,
            onChanged: (v) => _controller.setDeviceName(v.isEmpty ? 'Client' : v),
          ),
          const SizedBox(height: 12),
          // Scan buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: _controller.isScanning ? 'Stop Scan' : 'Scan Services',
                  icon: _controller.isScanning
                      ? Icons.stop_rounded
                      : Icons.bluetooth_searching_rounded,
                  color: _controller.isScanning
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF5B7BFE),
                  onTap: () async {
                    if (_controller.isScanning) {
                      await _controller.stopScan();
                    } else {
                      await _controller.startScan();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildButton(
                  label: 'Scan All',
                  icon: Icons.radar_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: _controller.isScanning
                      ? null
                      : () async => await _controller.startScanAll(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151B27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Your display name',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
          prefixIcon: Icon(
            Icons.badge_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? color : Colors.white.withValues(alpha: 0.2),
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? color : Colors.white.withValues(alpha: 0.2),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final devices = _controller.scanResults;

    if (devices.isEmpty) {
      return _buildEmptyState(
        icon: _controller.isScanning
            ? Icons.bluetooth_searching_rounded
            : Icons.bluetooth_disabled_rounded,
        title: _controller.isScanning ? 'Scanning...' : 'No devices found',
        subtitle: _controller.isScanning
            ? 'Looking for BLE servers nearby'
            : 'Tap Scan to search for servers',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) => _buildDeviceCard(devices[index]),
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
    final rssiColor = rssi >= -50
        ? const Color(0xFF22D3A5)
        : rssi >= -70
            ? const Color(0xFFF59E0B)
            : const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B7BFE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bluetooth_rounded,
                    color: Color(0xFF5B7BFE),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        device.remoteId.str,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
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
                        Icon(Icons.signal_cellular_alt_rounded,
                            color: rssiColor, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '$rssi dBm',
                          style: TextStyle(
                            color: rssiColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to connect',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 10.5,
                      ),
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

  Widget _buildMessageList() {
    final messages = _controller.messages;

    if (messages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Connected!',
        subtitle: 'Send a message to get started',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) => ChatBubble(
        message: messages[index],
        isMe: messages[index].isSent,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final success = await _controller.connectToServer(device);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.status),
          backgroundColor: const Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
