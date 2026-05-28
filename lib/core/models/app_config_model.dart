class AppConfigModel {
  final String storeName;
  final String storeHours;
  final String contactPhone;
  final String messengerLink;
  final String announcement;
  final double deliveryFee;
  final double minOrderAmount;
  final bool gcashEnabled;
  final List<String> searchHotwords;
  final int deliveryMinutes;

  const AppConfigModel({
    required this.storeName,
    required this.storeHours,
    required this.contactPhone,
    required this.messengerLink,
    required this.announcement,
    required this.deliveryFee,
    required this.minOrderAmount,
    this.gcashEnabled = false,
    this.searchHotwords = const [],
    this.deliveryMinutes = 30,
  });

  bool get hasAnnouncement => announcement.trim().isNotEmpty;
  bool get hasMessenger => messengerLink.trim().isNotEmpty;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final hotwordsRaw = data['searchHotwords']?.toString() ?? '';
    final hotwords = hotwordsRaw.isEmpty
        ? <String>[]
        : hotwordsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return AppConfigModel(
      storeName: data['storeName'] as String? ?? 'DodoMiniMart',
      storeHours: data['storeHours'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      messengerLink: data['messengerLink'] as String? ?? '',
      announcement: data['announcement'] as String? ?? '',
      deliveryFee: double.tryParse(data['deliveryFee']?.toString() ?? '') ?? 20.0,
      minOrderAmount: double.tryParse(data['minOrderAmount']?.toString() ?? '') ?? 0.0,
      gcashEnabled: data['gcashEnabled'] as bool? ?? false,
      searchHotwords: hotwords,
      deliveryMinutes: int.tryParse(data['deliveryMinutes']?.toString() ?? '') ?? 30,
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
    searchHotwords: [],
    deliveryMinutes: 30,
  );
}
