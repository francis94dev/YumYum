import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';

abstract class OrdersRepository {
  Future<List<OrderModel>> getOrders();
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return MockOrdersRepository();
});

class MockOrdersRepository implements OrdersRepository {
  @override
  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      OrderModel(
        id: 'ord1',
        product: ProductModel(
          id: '101',
          title: 'Tarta de Manzana Casera',
          description: 'He hecho demasiada tarta de manzana.',
          imageUrl: 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=500',
          owner: UserModel(id: '2', name: 'Ana', email: 'ana@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=5'),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          type: 'exchange',
          location: const LatLng(40.4168, -3.7038),
        ),
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        totalAmount: 0.0,
      ),
      OrderModel(
        id: 'ord2',
        product: ProductModel(
          id: '102',
          title: 'Tupper de Lentejas',
          description: 'Lentejas tradicionales con chorizo.',
          imageUrl: 'https://images.unsplash.com/photo-1548811218-12c8b87ee077?w=500',
          owner: UserModel(id: '3', name: 'Carlos', email: 'carlos@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=11'),
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          type: 'sell',
          price: 4.50,
          location: const LatLng(40.4200, -3.7000),
        ),
        orderDate: DateTime.now().subtract(const Duration(days: 3)),
        status: 'pending',
        totalAmount: 4.50,
      ),
    ];
  }
}
