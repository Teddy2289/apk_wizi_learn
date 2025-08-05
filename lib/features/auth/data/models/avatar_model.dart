class Avatar {
  final int id;
  final String name;
  final String image;
  final String? unlockCondition;
  final int pricePoints;
  final bool unlocked;

  Avatar({
    required this.id,
    required this.name,
    required this.image,
    this.unlockCondition,
    required this.pricePoints,
    this.unlocked = false,
  });

  factory Avatar.fromJson(Map<String, dynamic> json, {bool unlocked = false}) {
    return Avatar(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      unlockCondition: json['unlock_condition'],
      pricePoints: json['price_points'] ?? 0,
      unlocked: unlocked,
    );
  }
} 