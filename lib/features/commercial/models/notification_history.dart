class NotificationHistory {
  final String id;
  final String type; // 'email' or 'push'
  final String message;
  final String? subject;
  final String? segment;
  final int recipientCount;
  final DateTime sentAt;
  final String status; // 'sent', 'failed', 'pending'

  NotificationHistory({
    required this.id,
    required this.type,
    required this.message,
    this.subject,
    this.segment,
    required this.recipientCount,
    required this.sentAt,
    required this.status,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'].toString(),
      type: json['type'] ?? 'push',
      message: json['message'] ?? '',
      subject: json['subject'],
      segment: json['segment'],
      recipientCount: json['recipientCount'] ?? 0,
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'subject': subject,
      'segment': segment,
      'recipientCount': recipientCount,
      'sentAt': sentAt.toIso8601String(),
      'status': status,
    };
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final diff = now.difference(sentAt);

    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';

    return '${sentAt.day.toString().padLeft(2, '0')}/${sentAt.month.toString().padLeft(2, '0')}';
  }
}
