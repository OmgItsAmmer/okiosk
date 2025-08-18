class CustomerModel {
  final int? customerId; // Changed from String to int
  final String firstName;
  final String? lastName;
  final String phoneNumber;
  final String cnic; // New required field
  final String email;
  final DateTime? dob;
  final DateTime? createdAt;
  final String? gender;
  final String? authId;
  final String? fcmToken;


  CustomerModel({
    required this.customerId,
    required this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.cnic, // New required field
    required this.email,
    this.dob,
    this.createdAt,
    this.gender,
    this.authId,
    this.fcmToken,
  });

  // Static function to create an empty user model
  static CustomerModel empty() => CustomerModel(
        customerId: null, // Changed from empty string to -1
        firstName: '',
        lastName: null,
        phoneNumber: '',
        cnic: '', // New required field
        email: '',
        dob: null,
        createdAt: null,
        gender: null,
        authId: null,
        fcmToken: null,
      );

  // Full name convenience getter
  String get fullName => "$firstName ${lastName ?? ''}".trim();

  // Convert model to JSON
  Map<String, dynamic> toJson({bool isInsert = false}) {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'cnic': cnic, // New field
      'email': email,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'auth_uid': authId,
      'fcm_token': fcmToken,
    };

    if (!isInsert) {
      data['customer_id'] = customerId; // Use 'customer_id'
    }

    return data;
  }

  // Factory method to build from JSON
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customer_id'] as int, // Adjust field name and type
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String,
      cnic: json['cnic'] as String, // New field
      email: json['email'] as String,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      gender: json['gender'] as String?,
      authId: json['auth_uid'] as String?,
      fcmToken: json['fcm_token'] as String?,
    );
  }

  // Convert a JSON list into List<UserModel>
  static List<CustomerModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => CustomerModel.fromJson(json)).toList();
  }

  // CopyWith method
  CustomerModel copyWith({
    int? customerId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? cnic,
    String? email,
    DateTime? dob,
    DateTime? createdAt,
    String? gender,
    String? authId,
    String? fcmToken,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnic: cnic ?? this.cnic,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      authId: authId ?? this.authId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
