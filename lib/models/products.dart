class Products {
  final String id;
  final String names;
  final double price;
  final int stock;
  final int version;

  Products({
    required this.id,
    required this.names,
    required this.price,
    required this.stock,
    this.version = 0,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['id'].toString(),
      names: json['names'] ?? '',
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      version: json['version'] != null ? (json['version'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? 0,
      'names': names,
      'price': price,
      'stock': stock,
      'version': version,
    };
  }

  Products copyWith({
    String? id,
    String? names,
    double? price,
    int? stock,
    int? version,
  }) {
    return Products(
      id: id ?? this.id,
      names: names ?? this.names,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      version: version ?? this.version,
    );
  }
}
