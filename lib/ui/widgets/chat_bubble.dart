import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

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
        left: isMe ? 64 : 0,
        right: isMe ? 0 : 64,
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildMetaRow(),
          const SizedBox(height: 4),
          _buildBubble(),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) ...[
            Text(
              message.from,
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            message.formattedTime,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 10.5,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Text(
              message.from,
              style: const TextStyle(
                color: Color(0xFF5B7BFE),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF5B7BFE), Color(0xFF7C5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : const Color(0xFF151B27),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 5),
          bottomRight: Radius.circular(isMe ? 5 : 18),
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: const Color(0xFF5B7BFE).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        message.message,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.white.withValues(alpha: 0.88),
          fontSize: 15,
          height: 1.4,
          fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}
