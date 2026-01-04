/* --
      LIST OF Enums
      They cannot be created inside a class.
-- */

/// Switch of Custom Brand-Text-Size Widget
enum AppRole { admin, user }

enum TransactionType { buy, sell }

enum ProductType { single, variable }

enum ProductVisibility { published, hidden }

enum TextSizes { small, medium, large }

enum ImageType { asset, network, memory, file }

enum MediaCategory {
  folders,
  brands,
  categories,
  products,
  users,
  customers,
  salesman,
  guarantors,
  shop,
  vendors
}

enum OrderStatus { pending, ready, completed, cancelled }

enum PaymentMethods {
  paypal,
  googlePay,
  applePay,
  visa,
  masterCard,
  creditCard,
  paystack,
  razorPay,
  paytm,
  cod,
  pickup,
  cash, // Added cash payment method for POS
  jazzcash, // 🚀 JAZZCASH INTEGRATION - Added JazzCash payment method support
}

enum ShippingMethods {
  shipping, // Home delivery
  pickup, // Store pickup
}

enum VariationType { regular, small, medium, large }

enum StockLocation { shop, garage1, garage2 } // temporary

enum SaleType { cash, installment }

enum DurationType { duration, monthly, quarterly, yearly }

enum UnitType {
  item, // Individual items
  dozen, // 12 items
  gross, // 144 items (12 dozen)
  kilogram, // Weight in kg
  gram, // Weight in g
  liter, // Volume in L
  milliliter, // Volume in mL
  meter, // Length in m
  centimeter, // Length in cm
  inch, // Length in inches
  foot, // Length in feet
  yard, // Length in yards
  box, // Container
  pallet, // Shipping unit
  custom // Custom unit (will be handled separately)
}

enum InstallmentStatus {
  pending,
  paid,
  overdue,
  completed,
}

enum NotificationType {
  installment,
  alertStock,
  company,
  unknown,
}

enum ProductTag {
  choice,
  recommended,
  trending,
  hotSeller,
  flashSale,
  newArrival,
  authentic,
  sale, // Added for sales items
  featured, // Added for featured items
  new_product, // Added for new products
}

extension NotificationTypeExtension on String {
  NotificationType toNotificationType() {
    switch (this) {
      case 'installment':
        return NotificationType.installment;
      case 'alertStock':
        return NotificationType.alertStock;
      default:
        return NotificationType.unknown;
    }
  }



}

enum VoiceState {
  /// Initial state - not recording
  idle,

  /// Initializing audio recorder
  initializing,

  /// Recording audio from microphone
  recording,

  /// Streaming audio to backend
  streaming,

  /// Processing transcription
  processing,

  /// Transcription completed
  completed,

  /// Error occurred
  error,

  /// Connecting to WebSocket
  connecting,

  /// WebSocket disconnected
  disconnected,
}


/// Extension for Voice State
extension VoiceStateExtension on VoiceState {
  bool get isRecording => this == VoiceState.recording;
  bool get isProcessing =>
      this == VoiceState.processing || this == VoiceState.streaming;
  bool get isIdle => this == VoiceState.idle;
  bool get isError => this == VoiceState.error;
  bool get canStartRecording =>
      this == VoiceState.idle ||
      this == VoiceState.completed ||
      this == VoiceState.error;
}
