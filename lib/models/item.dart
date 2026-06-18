class Item {
  int? id;
  String name;
  String category;
  double pricePerDay;
  int stock;
  String? imagePath;
  DateTime createdAt;
  String type; // 'RENT' or 'SELL'

  Item({
    this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.stock,
    this.imagePath,
    required this.createdAt,
    this.type = 'RENT',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'pricePerDay': pricePerDay,
      'stock': stock,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      stock: map['stock'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      type: map['type'] ?? 'RENT',
    );
  }
}
