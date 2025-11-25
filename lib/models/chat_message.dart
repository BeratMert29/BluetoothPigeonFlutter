import 'dart:convert';

/// Represents a chat message sent over BLE
class ChatMessage {
  final String from;
  final String type;
  final String message;
  final int timestamp;
  final bool isSent; // true if sent by this device, false if received

  ChatMessage({
    required this.from,
    required this.type,
    required this.message,
    required this.timestamp,
    this.isSent = false,
  });

  /// Create a text message
  factory ChatMessage.text({
    required String from,
    required String message,
    bool isSent = false,
  }) {
    return ChatMessage(
      from: from,
      type: 'text',
      message: message,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isSent: isSent,
    );
  }

  /// Create from JSON string (received over BLE)
  factory ChatMessage.fromJsonString(String jsonString, {bool isSent = false}) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ChatMessage(
      from: json['from'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'text',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isSent: isSent,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'type': type,
      'message': message,
      'timestamp': timestamp,
    };
  }

  /// Convert to JSON string for BLE transmission
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Get formatted time string
  String get formattedTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'ChatMessage(from: $from, type: $type, message: $message, timestamp: $timestamp, isSent: $isSent)';
  }
}

