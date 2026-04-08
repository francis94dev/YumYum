import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/screens/feed_screen.dart'; // To reuse _ProductCard if it was public, but it's private.
// I'll re-implement a simple version or makes it public in feed_screen.dart.
// For now, I'll just import it and use a custom card or update feed_screen to export it.

import '../../product/providers/favorites_provider.dart';
import '../../product/repositories/product_repository.dart';
import '../../../core/widgets/app_image.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos')),
      body: productsAsync.when(
        data: (products) {
          final favProducts = products.where((p) => favIds.contains(p.id)).toList();
          
          if (favProducts.isEmpty) {
            return const Center(child: Text('No tienes favoritos todavía'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favProducts.length,
            itemBuilder: (context, index) {
              final product = favProducts[index];
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
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(product.id),
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
