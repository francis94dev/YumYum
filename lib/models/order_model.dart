import 'product_model.dart';

class OrderModel {
  final String id;
  final ProductModel product;
  final DateTime orderDate;
  final String status; // 'pending', 'completed', 'cancelled'
  final double totalAmount;

  OrderModel({
    required this.id,
    required this.product,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
  });
}
