import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/orders_repository.dart';
import '../../../core/widgets/app_image.dart';

final ordersProvider = FutureProvider((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: ordersAsync.when(
        data: (orders) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImage(
                    imageUrl: order.product.imageUrl,
                    width: 60,
                    height: 60,
                  ),
                ),
                title: Text(
                  order.product.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
                    Text(
                      'Estado: ${order.status == 'completed' ? 'Completado' : 'Pendiente'}',
                      style: TextStyle(
                        color: order.status == 'completed' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  order.product.type == 'exchange' ? 'Intercambio' : '${order.totalAmount.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
