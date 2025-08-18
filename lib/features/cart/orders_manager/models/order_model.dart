

import 'order_item_model.dart';

class OrderModel {
  final int orderId;
  final String orderDate;
  final double subTotal;
  final String status;
  final int? addressId;
  final double paidAmount;
  final int customerId;
  final int? userId;
  final String? saleType;
  final double buyingPrice;
  final double discount;
  final double tax;
  final double shippingFee;
  List<OrderItemModel> orderItems;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.subTotal,
    required this.status,
    required this.addressId,
    required this.paidAmount,
    required this.customerId,
    this.userId,
    this.saleType,
    required this.buyingPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    this.shippingFee = 0.0,
    required this.orderItems,
  });

  // Static function to create an empty order model
  static OrderModel empty() => OrderModel(
        orderId: 0,
        orderDate: DateTime.now().toIso8601String(),
        subTotal: 0.0,
        status: "",
        addressId: 0,
        paidAmount: 0.0,
        customerId: -1,
        userId: null,
        saleType: null,
        buyingPrice: 0.0,
        discount: 0.0,
        tax: 0.0,
        shippingFee: 0.0,
        orderItems: [],
      );

  // Convert model to JSON for database insertion
  Map<String, dynamic> toJson({bool isInsert = false}) {
    final Map<String, dynamic> data = {
      'order_date': orderDate,
      'sub_total': subTotal,
      'status': status,
      'address_id': addressId,
      'paid_amount': paidAmount,
      'customer_id': customerId,
      'user_id': userId,
      'sale_type': saleType,
      'buying_price': buyingPrice,
      'discount': discount,
      'tax': tax,
      'shipping_fee': shippingFee,
    };

    if (isInsert) {
      data['order_id'] = orderId;
    }

    return data;
  }

  // Factory method to create an OrderModel from Supabase response
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] as int,
      orderDate: json['order_date'] as String,
      subTotal: (json['sub_total'] as num).toDouble(),
      status: json['status'] as String,
      addressId: json['address_id'] as int?,
      paidAmount: (json['paid_amount'] as num).toDouble(),
      customerId: json['customer_id'] as int,
      userId: json['user_id'] as int?,
      saleType: json['sale_type'] as String?,
      buyingPrice: (json['buying_price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      orderItems: json['order_items'] != null
          ? OrderItemModel.fromJsonList(json['order_items'] as List)
          : [],
    );
  }

  // CopyWith method
  OrderModel copyWith({
    int? orderId,
    String? orderDate,
    double? subTotal,
    String? status,
    int? addressId,
    double? paidAmount,
    int? customerId,
    int? userId,
    String? saleType,
    double? buyingPrice,
    double? discount,
    double? tax,
    double? shippingFee,
    List<OrderItemModel>? orderItems,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      subTotal: subTotal ?? this.subTotal,
      status: status ?? this.status,
      addressId: addressId ?? this.addressId,
      paidAmount: paidAmount ?? this.paidAmount,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      saleType: saleType ?? this.saleType,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      shippingFee: shippingFee ?? this.shippingFee,
      orderItems: orderItems ?? this.orderItems,
    );
  }
}
