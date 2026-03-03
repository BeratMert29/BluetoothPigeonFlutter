import 'package:flutter/material.dart';

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
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
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
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1020),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF151B27),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _hasText
                      ? const Color(0xFF5B7BFE).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.enabled ? 'Message...' : 'Not connected',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _hasText && widget.enabled ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _hasText && widget.enabled
                    ? const LinearGradient(
                        colors: [Color(0xFF5B7BFE), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _hasText && widget.enabled
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                boxShadow: _hasText && widget.enabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5B7BFE).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _hasText && widget.enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
