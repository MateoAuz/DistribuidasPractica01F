import 'package:app_01/models/products.dart';
import 'package:app_01/pages/products_form_pages.dart';
import 'package:app_01/services/products_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';

/// Filtro de estado para la lista de productos.
enum _StatusFilter { all, active, inactive }

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductsService productsService = ProductsService();

  late Future<List<Products>> futureProducts;

  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  List<Products> _applyFilter(List<Products> products) {
    switch (_statusFilter) {
      case _StatusFilter.active:
        return products.where((p) => p.active).toList();
      case _StatusFilter.inactive:
        return products.where((p) => !p.active).toList();
      case _StatusFilter.all:
        return products;
    }
  }

  void _reload() {
    setState(() {
      futureProducts = productsService.getProducts();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _confirmAndDelete(Products product) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Está seguro de que desea eliminar "${product.names}"? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, eliminar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await productsService.deleteProduct(product.id);
      _showMessage('Producto eliminado correctamente.');
      _reload();
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
      _reload();
    } catch (e) {
      _showMessage('Ocurrió un error inesperado: $e', isError: true);
    }
  }

  /// Construye el contenido del área de error del FutureBuilder.
  /// - Si el problema fue no poder contactar al servidor
  ///   (ServerUnavailableException), muestra una pantalla dedicada con
  ///   ícono y mensaje claro de "servidor no disponible".
  /// - Para cualquier otro error, muestra el mensaje tal cual (ya viene
  ///   traducido a algo legible desde ProductsService).
  Widget _buildError(Object? error) {
    final isServerDown = error is ServerUnavailableException;

    final message = error is ApiException
        ? error.message
        : 'Ocurrió un error inesperado: $error';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isServerDown ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isServerDown ? 'Servidor no disponible' : 'Ocurrió un error',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products MAuz'),
        actions: [
          PopupMenuButton<_StatusFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            initialValue: _statusFilter,
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _StatusFilter.all,
                child: Text('Todos'),
              ),
              PopupMenuItem(
                value: _StatusFilter.active,
                child: Text('Activos'),
              ),
              PopupMenuItem(
                value: _StatusFilter.inactive,
                child: Text('Inactivos'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: 'Recargar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormPage()),
          );
          if (result == true) _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Products>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final allProducts = snapshot.data ?? [];
          final products = _applyFilter(allProducts);

          if (allProducts.isEmpty) {
            return const Center(child: Text('No hay productos registrados.'));
          }

          if (products.isEmpty) {
            return const Center(
              child: Text('No hay productos que coincidan con el filtro.'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                key: ValueKey(product.id),
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: (product.image == null || product.image!.isEmpty)
                          ? Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey,
                              ),
                            )
                          : CachedNetworkImage(
                              key: ValueKey(product.image),
                              imageUrl: product.image!,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              // En Flutter Web, el modo por defecto (HtmlImage)
                              // dibuja la textura a partir de un <img>/Blob que
                              // puede quedar liberado al reconstruirse el widget
                              // (reload), pintando la imagen en negro
                              // (WebGL texImage2D: no image). HttpGet decodifica
                              // los bytes directamente con Skia y evita ese bug.
                              imageRenderMethodForWeb:
                                  ImageRenderMethodForWeb.HttpGet,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  title: Text(product.names),
                  subtitle: Text(
                    'Precio: \$${product.price.toStringAsFixed(2)}\nStock: ${product.stock}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product.active
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: product.active ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductFormPage(product: product),
                            ),
                          );
                          if (result == true) _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmAndDelete(product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}