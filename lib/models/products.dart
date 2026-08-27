class Products {
  final String id;
  final String names;
  final double price;
  final int stock;

  Products({
    required this.id,
    required this.names,
    required this.price,
    required this.stock,
  });


  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['id'].toString(),
      names: json['names'],
      price: json['price'].toDouble(),
      stock: json['stock'].toInt(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': int.parse(id ?? '0'),
      'names': names,
      'price': price,
      'stock': stock,
    };
  }
}