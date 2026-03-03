import 'package:flutter/material.dart';
import '../ble/ble_server_controller.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_input.dart';

class ServerChatScreen extends StatefulWidget {
  const ServerChatScreen({super.key});

  @override
  State<ServerChatScreen> createState() => _ServerChatScreenState();
}

class _ServerChatScreenState extends State<ServerChatScreen> {
  late BleServerController _controller;
  final TextEditingController _nameController =
      TextEditingController(text: 'Server');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = BleServerController();
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
    _controller.stopServer();
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
          _buildControlPanel(),
          Expanded(child: _buildMessageList()),
          if (_controller.isServerRunning &&
              _controller.connectedDevices.isNotEmpty)
            MessageInput(
              onSend: _controller.sendMessage,
              enabled: _controller.connectedDevices.isNotEmpty,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final clientCount = _controller.connectedDevices.length;

    return AppBar(
      backgroundColor: const Color(0xFF0F1020),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7BFE).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cell_tower_rounded,
              color: Color(0xFF5B7BFE),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'BLE Peripheral',
                style: TextStyle(
                  color: Color(0xFF5B7BFE),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (clientCount > 0)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22D3A5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF22D3A5).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded,
                    color: Color(0xFF22D3A5), size: 15),
                const SizedBox(width: 5),
                Text(
                  '$clientCount',
                  style: const TextStyle(
                    color: Color(0xFF22D3A5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusStrip() {
    final color = _controller.isServerRunning
        ? (_controller.isAdvertising
            ? const Color(0xFF22D3A5)
            : const Color(0xFFF59E0B))
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
          _buildNameField(),
          const SizedBox(height: 12),
          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: _controller.isServerRunning ? 'Stop Server' : 'Start Server',
                  icon: _controller.isServerRunning
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: _controller.isServerRunning
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF5B7BFE),
                  onTap: () async {
                    if (_controller.isServerRunning) {
                      await _controller.stopServer();
                    } else {
                      await _controller.startServer();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildButton(
                  label: _controller.isAdvertising ? 'Stop Advert' : 'Advertise',
                  icon: _controller.isAdvertising
                      ? Icons.wifi_off_rounded
                      : Icons.wifi_tethering_rounded,
                  color: _controller.isAdvertising
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22D3A5),
                  onTap: _controller.isServerRunning
                      ? () async {
                          if (_controller.isAdvertising) {
                            await _controller.stopAdvertising();
                          } else {
                            await _controller.startAdvertising();
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151B27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Your display name',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
          prefixIcon: Icon(
            Icons.badge_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          isDense: true,
        ),
        onChanged: (value) {
          _controller.setDeviceName(value.isEmpty ? 'Server' : value);
        },
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
            color: enabled
                ? color.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.07),
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

  Widget _buildMessageList() {
    final messages = _controller.messages;

    if (messages.isEmpty) {
      return _buildEmptyState();
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

  Widget _buildEmptyState() {
    final subtitle = _controller.isServerRunning
        ? _controller.connectedDevices.isEmpty
            ? 'Waiting for a client to connect'
            : 'Send a message to get started'
        : 'Start the server to begin';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
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
}
