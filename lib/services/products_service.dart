import 'dart:convert';

import 'package:app_01/models/products.dart';
import 'package:http/http.dart' as http;

/// Excepción genérica para errores de la API (validación, no encontrado, etc.)
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Excepción específica para conflictos de concurrencia (HTTP 409):
/// otro usuario modificó o eliminó el producto antes que nosotros.
class ConflictException extends ApiException {
  final Products? current;
  ConflictException(super.message, this.current);
}

class ProductsService {
  // IMPORTANTE (trabajo en parejas):
  // - El estudiante que ejecuta el backend (servidor) debe correrlo
  //   escuchando en 0.0.0.0 (ver launchSettings.json) y compartir su IP
  //   dentro de la red local, por ejemplo: 192.168.1.25
  // - El estudiante que ejecuta la app Flutter (cliente) debe reemplazar
  //   'localhost' por esa IP del servidor. 'localhost' solo funciona si el
  //   backend corre en la MISMA máquina que la app.
  final String url = "http://localhost:5050/api/Products";

  Future<List<Products>> getProducts() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List datos = jsonDecode(response.body);
      return datos.map((item) => Products.fromJson(item)).toList();
    }

    throw ApiException(_extractMessage(response, 'Error al cargar los productos.'));
  }

  Future<Products> createProduct(Products product) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['product'] ?? body;
      return Products.fromJson(data);
    }

    if (response.statusCode == 400) {
      throw ApiException(_extractMessage(response, 'Datos inválidos.'));
    }

    throw ApiException(_extractMessage(response, 'Error al crear el producto.'));
  }

  Future<Products> updateProduct(Products product) async {
    final response = await http.put(
      Uri.parse('$url/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        final data = body['product'] ?? body;
        return Products.fromJson(data);
      }
      return product;
    }

    if (response.statusCode == 409) {
      final body = jsonDecode(response.body);
      final current = body['current'] != null
          ? Products.fromJson(body['current'])
          : null;
      throw ConflictException(
        _extractMessage(response, 'El producto fue modificado por otro usuario.'),
        current,
      );
    }

    if (response.statusCode == 404) {
      throw ApiException(_extractMessage(response, 'El producto ya no existe.'));
    }

    if (response.statusCode == 400) {
      throw ApiException(_extractMessage(response, 'Datos inválidos.'));
    }

    throw ApiException(_extractMessage(response, 'Error al actualizar el producto.'));
  }

  Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('$url/$id'));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiException(_extractMessage(response, 'El producto ya no existe (puede que otro usuario ya lo haya eliminado).'));
    }

    throw ApiException(_extractMessage(response, 'Error al eliminar el producto.'));
  }

  String _extractMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {
      // El cuerpo no era JSON válido; se usa el mensaje por defecto.
    }
    return fallback;
  }
}