class OnlineUser {
  final String id;
  final String name;
  final String? role;
  final int onlineDuration; // in minutes

  OnlineUser({
    required this.id,
    required this.name,
    this.role,
    required this.onlineDuration,
  });

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    return OnlineUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      role: json['role'],
      onlineDuration: json['onlineDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'onlineDuration': onlineDuration,
    };
  }

  String getInitials() {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String getFormattedDuration() {
    if (onlineDuration < 1) return "À l'instant";
    if (onlineDuration < 60) return '${onlineDuration}min';
    final hours = onlineDuration ~/ 60;
    final mins = onlineDuration % 60;
    return mins > 0 ? '${hours}h${mins}min' : '${hours}h';
  }
}
