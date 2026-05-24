class AppConfigModel {
  final String storeName;
  final String storeHours;
  final String contactPhone;
  final String messengerLink;
  final String announcement;
  final double deliveryFee;
  final double minOrderAmount;
  final bool gcashEnabled;

  const AppConfigModel({
    required this.storeName,
    required this.storeHours,
    required this.contactPhone,
    required this.messengerLink,
    required this.announcement,
    required this.deliveryFee,
    required this.minOrderAmount,
    this.gcashEnabled = false,
  });

  bool get hasAnnouncement => announcement.trim().isNotEmpty;
  bool get hasMessenger => messengerLink.trim().isNotEmpty;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AppConfigModel(
      storeName: data['storeName'] as String? ?? 'DodoMiniMart',
      storeHours: data['storeHours'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      messengerLink: data['messengerLink'] as String? ?? '',
      announcement: data['announcement'] as String? ?? '',
      deliveryFee: double.tryParse(data['deliveryFee']?.toString() ?? '') ?? 20.0,
      minOrderAmount: double.tryParse(data['minOrderAmount']?.toString() ?? '') ?? 0.0,
      gcashEnabled: data['gcashEnabled'] as bool? ?? false,
    );
  }

  // Fallback defaults when API is unavailable
  static const fallback = AppConfigModel(
    storeName: 'DodoMiniMart',
    storeHours: '',
    contactPhone: '',
    messengerLink: '',
    announcement: '',
    deliveryFee: 20.0,
    minOrderAmount: 0.0,
    gcashEnabled: false,
  );
}
