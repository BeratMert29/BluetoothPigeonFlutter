import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

/// A chat bubble widget for displaying messages
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name and time
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.from,
                  style: TextStyle(
                    color: isMe
                        ? const Color(0xFF00D9FF).withOpacity(0.8)
                        : const Color(0xFF00FF94).withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.formattedTime,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMe ? null : const Color(0xFF21262D),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? const Color(0xFF00D9FF).withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMe ? const Color(0xFF0D1117) : Colors.white,
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

