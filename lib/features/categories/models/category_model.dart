class CategoryModel {
  int categoryId;
  String categoryName;
  bool isFeatured;
  DateTime? createdAt;
  final int productCount;


  
  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.isFeatured = false,
    this.createdAt,
    this.productCount = 0,
  });

  // Static function to create an empty category model
  static CategoryModel empty() => CategoryModel(
        categoryId: -1,
        categoryName: "",
        isFeatured: false,
        createdAt: null,
        productCount: 0,
      );

  // Convert model to JSON for database insertion
  Map<String, dynamic> toJson({bool isInsert = false}) {
    final Map<String, dynamic> data = {
      'category_name': categoryName,
      'isFeatured': isFeatured,
      'product_count': productCount,
    };

    if (!isInsert) {
      data['category_id'] = categoryId; // Include category_id for insert
    }

    return data;
  }

  // Factory method to create a CategoryModel from Supabase response
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      isFeatured: json['isFeatured'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      productCount: json['product_count'] as int,
    );
  }

  // CopyWith method
  CategoryModel copyWith({
    int? categoryId,
    String? categoryName, 
    bool? isFeatured,
    DateTime? createdAt,
    int? productCount,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      productCount: productCount ?? this.productCount,
      );
  }
}
