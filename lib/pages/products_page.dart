import 'package:app_01/models/products.dart';
import 'package:app_01/pages/products_form_pages.dart';
import 'package:app_01/services/products_service.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
const ProductsPage({super.key});

@override
State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  
  final ProductsService productsService = ProductsService();

  late Future<List<Products>> futureProducts;
  @override
  void initState() {
    super.initState();
    futureProducts = productsService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products MAuz'),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormPage()),
          ).then((_) {
            setState(() {
              futureProducts = productsService.getProducts(); // recarga la lista
            });
          });
        },
        
      ),

      body: FutureBuilder<List<Products>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center (child: CircularProgressIndicator(),);
          } 
          if(snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'),);
          }

          final products = snapshot.data ?? [];

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(product.names),
                  subtitle: Text(
                    'Price: \$${product.price}\nStock: ${product.stock}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductFormPage(product: product),
                              )
                            );

                            setState(() {
                              futureProducts = productsService.getProducts();//recarga la lista
                            }); 
                        }
                        ),
                        IconButton(
                        icon:  Icon(Icons.delete),
                        onPressed: () async {
                          await productsService.deleteProduct(product.id ?? '0');
                          setState(() {
                            futureProducts = productsService.getProducts(); // recarga la lista
                          });
                        },
                      )
                    ],
                  )
                ),
              );
            },
          );
        }
      )
    );
  }

}