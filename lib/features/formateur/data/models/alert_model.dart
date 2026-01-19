import 'package:flutter/foundation.dart';

/// Alert model for trainer dashboard
class FormateurAlert {
  final String id;
  final String type; // danger, warning, info
  final String category; // inactivity, deadline, performance, dropout, never_connected
  final String title;
  final String message;
  final int? stagiaireId;
  final String? stagiaireName;
  final String priority; // high, medium, low
  final String createdAt;
  final Map<String, dynamic>? metadata;

  FormateurAlert({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.stagiaireId,
    this.stagiaireName,
    required this.priority,
    required this.createdAt,
    this.metadata,
  });

  factory FormateurAlert.fromJson(Map<String, dynamic> json) {
    return FormateurAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      stagiaireId: json['stagiaire_id'] != null
          ? int.tryParse(json['stagiaire_id'].toString())
          : null,
      stagiaireName: json['stagiaire_name']?.toString(),
      priority: json['priority']?.toString() ?? 'low',
      createdAt: json['created_at']?.toString() ?? '',
      metadata: json,
    );
  }

  bool get isHighPriority => priority == 'high';
  bool get isDanger => type == 'danger';
}

/// Alert statistics
class AlertStats {
  final int inactive;
  final int approachingDeadline;
  final int lowPerformance;
  final int neverConnected;
  final int total;

  AlertStats({
    required this.inactive,
    required this.approachingDeadline,
    required this.lowPerformance,
    required this.neverConnected,
    required this.total,
  });

  factory AlertStats.fromJson(Map<String, dynamic> json) {
    return AlertStats(
      inactive: int.tryParse(json['inactive']?.toString() ?? '0') ?? 0,
      approachingDeadline: int.tryParse(json['approaching_deadline']?.toString() ?? '0') ?? 0,
      lowPerformance: int.tryParse(json['low_performance']?.toString() ?? '0') ?? 0,
      neverConnected: int.tryParse(json['never_connected']?.toString() ?? '0') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    );
  }
}
