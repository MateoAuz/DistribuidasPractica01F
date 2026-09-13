class Products {
  final String id;
  final String names;
  final double price;
  final int stock;
  final String? description;
  final String? image;
  final bool active;
  final int version;

  Products({
    required this.id,
    required this.names,
    required this.price,
    required this.stock,
    this.description,
    this.image,
    this.active = true,
    this.version = 0,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['id'].toString(),
      names: json['names'] ?? '',
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      description: json['description'] as String?,
      image: json['image'] as String?,
      active: json['active'] as bool? ?? true,
      version: json['version'] != null ? (json['version'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? 0,
      'names': names,
      'price': price,
      'stock': stock,
      'description': description,
      'image': image,
      'active': active,
      'version': version,
    };
  }

  Products copyWith({
    String? id,
    String? names,
    double? price,
    int? stock,
    String? description,
    String? image,
    bool? active,
    int? version,
  }) {
    return Products(
      id: id ?? this.id,
      names: names ?? this.names,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      image: image ?? this.image,
      active: active ?? this.active,
      version: version ?? this.version,
    );
  }
}
