import 'package:flutter/material.dart';

/// A message input widget with send button
class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool enabled;

  const MessageInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasText
                      ? const Color(0xFF00D9FF).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.enabled ? 'Type a message...' : 'Connecting...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _hasText && widget.enabled ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _hasText && widget.enabled
                    ? const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0099FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _hasText && widget.enabled ? null : const Color(0xFF21262D),
                shape: BoxShape.circle,
                boxShadow: _hasText && widget.enabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D9FF).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _hasText && widget.enabled
                    ? const Color(0xFF0D1117)
                    : Colors.white.withOpacity(0.3),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

