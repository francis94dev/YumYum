import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../product/repositories/product_repository.dart';
import '../../feed/screens/feed_screen.dart'; // We could export _ProductCard but it's easier to recreate a simple list or make it public.
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/app_image.dart';

class MyOffersScreen extends ConsumerWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión para ver tus ofertas')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Ofertas Publicadas')),
      body: productsAsync.when(
        data: (products) {
          // In a real app, this would be a specific API call. 
          // Here we filter the mock list to only show products by "me".
          // The mock products in repository have specific IDs. AddUser products will have the user's ID.
          final myProducts = products.where((p) => p.owner.id == user.id).toList();

          if (myProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No has publicado ninguna oferta todavía'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/add'),
                    child: const Text('Publicar mi primera oferta'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myProducts.length,
            itemBuilder: (context, index) {
              final product = myProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  onTap: () => context.push('/product/${product.id}'),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(imageUrl: product.imageUrl, width: 60, height: 60),
                  ),
                  title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Activa', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
