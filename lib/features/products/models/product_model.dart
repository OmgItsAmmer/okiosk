import 'product_variation_model.dart';

class ProductModel {
  int productId;
  String name;
  String? description;
  String priceRange;
  String basePrice;
  String salePrice;
  int? categoryId;
  bool isPopular;
  int stockQuantity;
  DateTime? createdAt;
  int? brandID;
  int? alertStock;

  bool isVisible;
  String? tag;
  List<ProductVariationModel> productVariants;

  ProductModel({
    required this.productId,
    required this.name,
    this.description,
    required this.priceRange,
    required this.basePrice,
    required this.salePrice,
    this.categoryId,
    this.isPopular = false,
    required this.stockQuantity,
    this.createdAt,
    this.brandID,
    this.alertStock,
    this.isVisible = false,
    this.tag,
    this.productVariants = const [],
  });

  // Static function to create an empty product model
  static ProductModel empty() => ProductModel(
        productId: -1,
        name: "",
        description: "",
        priceRange: "",
        basePrice: "",
        salePrice: "",
        categoryId: null,
        isPopular: false,
        stockQuantity: 0,
        createdAt: null,
        brandID: null,
        alertStock: null,
        isVisible: false,
        tag: null,
        productVariants: [],
      );

  // Convert model to JSON for database insertion
  Map<String, dynamic> toJson({bool isInsert = false, bool isSerial = false}) {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description ?? '',
      'price_range': priceRange,
      'base_price': basePrice,
      'sale_price': salePrice,
      'category_id': categoryId,
      'is_popular': isPopular,
      if (!isSerial) 'stock_quantity': stockQuantity,
      'brandID': brandID,
      'alert_stock': alertStock,
      'isVisible': isVisible,
      'tag': tag,
      'product_variants': productVariants.map((e) => e.toJson()).toList(),
    };

    if (isInsert) {
      data['product_id'] = productId; // Include product_id for update
    }

    return data;
  }

  // Factory method to create a ProductModel from Supabase response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceRange: json['price_range'] as String,
      basePrice: json['base_price'] as String,
      salePrice: json['sale_price'] as String,
      categoryId: json['category_id'] as int?,
      isPopular: json['is_popular'] as bool? ?? false,
      stockQuantity: json['stock_quantity'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      brandID: json['brandID'] as int?,
      alertStock: json['alert_stock'] as int?,
      isVisible: json['isVisible'] as bool? ?? false,
      tag: json['tag'] as String?,
      productVariants: (json['product_variants'] as List<dynamic>?)
              ?.map((e) =>
                  ProductVariationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // CopyWith method
  ProductModel copyWith({
    int? productId,
    String? name,
    String? description,
    String? priceRange,
    String? basePrice,
    String? salePrice,
    int? categoryId,
    bool? isPopular,
    int? stockQuantity,
    DateTime? createdAt,
    int? brandID,
    int? alertStock,
    bool? hasSerialNumbers,
    bool? isVisible,
    String? tag,
    List<ProductVariationModel>? productVariants,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceRange: priceRange ?? this.priceRange,
      basePrice: basePrice ?? this.basePrice,
      salePrice: salePrice ?? this.salePrice,
      categoryId: categoryId ?? this.categoryId,
      isPopular: isPopular ?? this.isPopular,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      brandID: brandID ?? this.brandID,
      alertStock: alertStock ?? this.alertStock,
      isVisible: isVisible ?? this.isVisible,
      tag: tag ?? this.tag,
      productVariants: productVariants ?? this.productVariants,
    );
  }
}
