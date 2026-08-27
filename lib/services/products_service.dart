import 'dart:convert';

import 'package:app_01/models/products.dart';
import 'package:http/http.dart' as http;

class ProductsService {
  final String url = "http://localhost:5050/api/Products";

  Future <List<Products>> getProducts() async {
    final response = await http.get(Uri.parse(url));
    if(response.statusCode == 200){
      List datos = jsonDecode(response.body);
      return datos.map((item) => Products.fromJson(item)).toList();
    }else{
      throw Exception('Error al cargar los productos');
    }
  }

  Future<void> createProduct(Products product) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear el producto');
    }
  }

  Future<void> updateProduct(Products product) async {
    final response = await http.put(
      Uri.parse('$url/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al actualizar el producto');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('$url/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar el producto');
    }
  }

}