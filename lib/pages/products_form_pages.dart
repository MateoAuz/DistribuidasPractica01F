
import 'package:app_01/models/products.dart';
import 'package:app_01/services/products_service.dart';
import 'package:flutter/material.dart';


class ProductFormPage extends StatefulWidget {
    final  Products? product;
   const ProductFormPage({super.key, this.product});
   @override
   State<ProductFormPage> createState() => _ProductFormPageState();
 }
 
 class _ProductFormPageState extends State<ProductFormPage> {
  final namesController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  final ProductsService productsService = ProductsService();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      namesController.text = widget.product!.names ?? '';
      priceController.text = widget.product!.price.toString() ?? '';
      stockController.text = widget.product!.stock.toString() ?? '';
    }
  }

  Future<void> saveUpdateProduct() async {
    final product = Products(
      id: widget.product?.id ?? 0.toString(),
      names: namesController.text,
      price: double.parse(priceController.text) ?? 0.0,
      stock: int.parse(stockController.text) ?? 0,
    );

    if (widget.product != null) {
      // Update existing product logic here
      await productsService.updateProduct(product);
    } else {
      //Create
      await productsService.createProduct(product);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        widget.product != null ? Text('Edit Product') : Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: namesController,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: saveUpdateProduct,
              child: widget.product != null ? Text('Update') : Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
}