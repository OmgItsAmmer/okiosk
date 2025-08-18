

import '../../cart/model/cart_model.dart';
import '../../cart/orders_manager/models/order_item_model.dart';
import '../../cart/orders_manager/models/order_model.dart';

class CheckoutModel {
  final OrderModel order;
  final List<OrderItemModel> orderItems;
  final List<CartModel> cartItems;

  CheckoutModel({
    required this.order,
    required this.orderItems,
    required this.cartItems,
  });

  // Static function to create an empty CheckoutModel
  static CheckoutModel empty() => CheckoutModel(
        order: OrderModel.empty(),
        orderItems: [],
        cartItems: [],
      );

  // Convert model to JSON for database insertion
  Map<String, dynamic> toJson() {
    return {
      'order': order.toJson(),
      'order_items': orderItems.map((item) => item.toJson()).toList(),
      'cart_items': cartItems.map((item) => item.toJson()).toList(),
    };
  }

  // Factory method to create a CheckoutModel from JSON response
  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    return CheckoutModel(
      order: OrderModel.fromJson(json['order']),
      orderItems: json['order_items'] != null
          ? OrderItemModel.fromJsonList(json['order_items'] as List)
          : [],
      cartItems: json['cart_items'] != null
          ? (json['cart_items'] as List)
              .map((item) => CartModel.fromJson(item))
              .toList()
          : [],
    );
  }

  // Merge function to combine OrderModel, OrderItemModel, and CartModel into a single CheckoutModel
  static CheckoutModel merge({
    required OrderModel order,
    required List<OrderItemModel> orderItems,
    required List<CartModel> cartItems,
  }) {
    return CheckoutModel(
      order: order,
      orderItems: orderItems,
      cartItems: cartItems,
    );
  }

  // CopyWith method
  CheckoutModel copyWith({
    OrderModel? order,
    List<OrderItemModel>? orderItems,
    List<CartModel>? cartItems,
  }) {
    return CheckoutModel(
      order: order ?? this.order,
      orderItems: orderItems ?? this.orderItems,
      cartItems: cartItems ?? this.cartItems,
    );
  }

  // Getter to extract the OrderModel
  OrderModel getOrderModel() {
    return order;
  }

  // Getter to extract the list of OrderItemModel
  List<OrderItemModel> getOrderItemModels() {
    return orderItems;
  }

  // Getter to extract the list of CartModel
  List<CartModel> getCartModels() {
    return cartItems;
  }
}
