import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/rating_bar.dart';
import '../repositories/product_repository.dart';
import '../providers/favorites_provider.dart';
import '../../feed/screens/feed_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/rating_repository.dart';
import '../../../models/rating_model.dart';
import 'package:uuid/uuid.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  void _showRatingDialog(BuildContext context, WidgetRef ref, String targetId) {
    int ratingValue = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valorar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(builder: (context, setState) {
              return RatingBar(
                rating: ratingValue.toDouble(),
                onRatingChanged: (v) => setState(() => ratingValue = v),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(authProvider).value;
              if (user == null) return;

              final rating = RatingModel(
                id: const Uuid().v4(),
                targetId: targetId,
                targetType: 'recipe',
                authorId: user.id,
                value: ratingValue,
                comment: commentController.text,
              );

              await ref.read(ratingRepositoryProvider).addRating(rating);
              ref.invalidate(ratingsProvider(targetId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final ratingsAsync = ref.watch(ratingsProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(favoritesProvider).contains(productId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: ref.watch(favoritesProvider).contains(productId)
                  ? Colors.red
                  : null,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(productId);
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final productOpt = products.where((p) => p.id == productId).toList();
          if (productOpt.isEmpty) {
            return const Center(child: Text('Producto no encontrado'));
          }
          final product = productOpt.first;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'img-${product.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppImage(
                      imageUrl: product.imageUrl,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              product.type == 'exchange' 
                                  ? 'Intercambio' 
                                  : '${product.price?.toStringAsFixed(2)} €',
                              style: TextStyle(
                                  color: product.type == 'exchange' ? Colors.purple.shade900 : Colors.green.shade900,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: product.type == 'exchange' ? Colors.purple.shade100 : Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.owner.profileImageUrl),
                        ),
                        title: Text(product.owner.name),
                        subtitle: const Text('Ver perfil'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripción',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Alérgenos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      product.allergens.isEmpty
                          ? const Text('Sin alérgenos conocidos', style: TextStyle(color: Colors.grey))
                          : Wrap(
                              spacing: 8,
                              children: product.allergens.map((allergen) {
                                return Chip(
                                  label: Text(allergen),
                                  backgroundColor: Colors.orange.shade50,
                                  labelStyle: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                                  side: BorderSide(color: Colors.orange.shade200),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Valoraciones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _showRatingDialog(context, ref, productId),
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Valorar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ratingsAsync.when(
                        data: (ratings) {
                          if (ratings.isEmpty) {
                            return const Text('Aún no hay valoraciones.', style: TextStyle(color: Colors.grey));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ratings.length,
                            itemBuilder: (context, index) {
                              final rating = ratings[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: RatingBar(rating: rating.value.toDouble(), size: 16),
                                subtitle: rating.comment != null && rating.comment!.isNotEmpty
                                    ? Text(rating.comment!)
                                    : null,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Create chat or navigate to chat
              context.push('/chat_room/chat1'); // mock chat id
            },
            child: const Text('Contactar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
