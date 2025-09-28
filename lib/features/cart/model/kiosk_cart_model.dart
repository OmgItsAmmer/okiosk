/// Kiosk Cart Model - Represents a single kiosk cart entry in the database
///
/// This model follows the Single Responsibility Principle by only handling
/// kiosk cart data representation and transformation. It's immutable and provides
/// clear contract for kiosk cart operations.
///
/// Database Schema Mapping:
/// - kiosk_id: Primary key (auto-generated)
/// - kiosk_session_id: UUID for kiosk session identification
/// - variant_id: Foreign key to product_variants table
/// - quantity: Integer representation of item quantity
/// - created_at: Timestamp when the item was added
class KioskCartModel {
  final int kioskId;
  final String kioskSessionId;
  final int variantId;
  final int quantity;
  final DateTime? createdAt;

  /// Creates a new KioskCartModel instance
  ///
  /// All fields are final to ensure immutability and prevent accidental modifications
  const KioskCartModel({
    required this.kioskId,
    required this.kioskSessionId,
    required this.variantId,
    required this.quantity,
    this.createdAt,
  });

  /// Creates an empty kiosk cart model for initialization purposes
  ///
  /// Uses factory pattern to provide a standard way of creating empty instances
  static KioskCartModel empty() => const KioskCartModel(
        kioskId: -1,
        kioskSessionId: '',
        variantId: 0,
        quantity: 0,
        createdAt: null,
      );

  /// Converts model to JSON for database operations
  ///
  /// Excludes kiosk_id for insert operations, includes it for updates
  /// This follows the Interface Segregation Principle by providing different
  /// interfaces for different operations
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final Map<String, dynamic> data = {
      'kiosk_session_id': kioskSessionId,
      'variant_id': variantId,
      'quantity': quantity,
    };

    if (isUpdate && kioskId > 0) {
      data['kiosk_id'] = kioskId;
    }

    return data;
  }

  /// Factory constructor to create KioskCartModel from database response
  ///
  /// Handles null safety and provides default values for missing fields
  factory KioskCartModel.fromJson(Map<String, dynamic> json) {
    return KioskCartModel(
      kioskId: json['kiosk_id'] as int? ?? -1,
      kioskSessionId: json['kiosk_session_id'] as String? ?? '',
      variantId: json['variant_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Creates a copy of this model with updated fields
  ///
  /// Enables immutable updates following functional programming principles
  KioskCartModel copyWith({
    int? kioskId,
    String? kioskSessionId,
    int? variantId,
    int? quantity,
    DateTime? createdAt,
  }) {
    return KioskCartModel(
      kioskId: kioskId ?? this.kioskId,
      kioskSessionId: kioskSessionId ?? this.kioskSessionId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Validates if the kiosk cart item is valid
  bool get isValid =>
      kioskSessionId.isNotEmpty && variantId > 0 && quantity > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KioskCartModel &&
          runtimeType == other.runtimeType &&
          kioskId == other.kioskId &&
          kioskSessionId == other.kioskSessionId &&
          variantId == other.variantId;

  @override
  int get hashCode =>
      kioskId.hashCode ^ kioskSessionId.hashCode ^ variantId.hashCode;

  @override
  String toString() {
    return 'KioskCartModel(kioskId: $kioskId, kioskSessionId: $kioskSessionId, variantId: $variantId, quantity: $quantity, createdAt: $createdAt)';
  }
}
