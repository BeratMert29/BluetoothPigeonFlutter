import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ble/ble_server_controller.dart';
import '../models/chat_message.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_input.dart';

/// Chat screen for Server mode (Phone A - Peripheral)
class ServerChatScreen extends StatefulWidget {
  const ServerChatScreen({super.key});

  @override
  State<ServerChatScreen> createState() => _ServerChatScreenState();
}

class _ServerChatScreenState extends State<ServerChatScreen> {
  late BleServerController _controller;
  final TextEditingController _nameController = TextEditingController(text: 'Server');
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusBar(),
          _buildControlPanel(),
          Expanded(child: _buildMessageList()),
          if (_controller.isServerRunning && _controller.connectedDevices.isNotEmpty)
            MessageInput(
              onSend: (text) {
                _controller.sendMessage(text);
              },
              enabled: _controller.connectedDevices.isNotEmpty,
            ),
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
                colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cell_tower,
              color: Color(0xFF0D1117),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'BLE Peripheral',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_controller.connectedDevices.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF94).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF00FF94), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_controller.connectedDevices.length}',
                  style: const TextStyle(
                    color: Color(0xFF00FF94),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
              color: _controller.isServerRunning
                  ? (_controller.isAdvertising
                      ? const Color(0xFF00FF94)
                      : const Color(0xFFFFD60A))
                  : const Color(0xFFFF453A),
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
                _controller.setDeviceName(value.isEmpty ? 'Server' : value);
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  label: _controller.isServerRunning ? 'Stop Server' : 'Start Server',
                  icon: _controller.isServerRunning ? Icons.stop : Icons.play_arrow,
                  color: _controller.isServerRunning
                      ? const Color(0xFFFF453A)
                      : const Color(0xFF00D9FF),
                  onPressed: () async {
                    if (_controller.isServerRunning) {
                      await _controller.stopServer();
                    } else {
                      await _controller.startServer();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  label: _controller.isAdvertising ? 'Stop Advert' : 'Advertise',
                  icon: _controller.isAdvertising ? Icons.wifi_off : Icons.wifi_tethering,
                  color: _controller.isAdvertising
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFF00FF94),
                  onPressed: _controller.isServerRunning
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
              'No messages yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.isServerRunning
                  ? 'Wait for a client to connect'
                  : 'Start the server to begin',
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

