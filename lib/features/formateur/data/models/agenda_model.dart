
class AgendaEvent {
  final int id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? status;
  final String? eventType;

  AgendaEvent({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.location,
    this.status,
    this.eventType,
  });

  factory AgendaEvent.fromJson(Map<String, dynamic> json) {
    return AgendaEvent(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['titre'] ?? json['summary'] ?? 'Événement sans titre',
      description: json['description'],
      start: DateTime.parse(json['date_debut'] ?? json['start'] ?? DateTime.now().toIso8601String()),
      end: DateTime.parse(json['date_fin'] ?? json['end'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String()),
      location: json['location'],
      status: json['status'],
      eventType: json['evenement'] ?? json['eventType'],
    );
  }

  bool get isUpcoming => start.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return start.year == now.year && start.month == now.month && start.day == now.day;
  }
}
