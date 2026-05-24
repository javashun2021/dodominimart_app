class AddressModel {
  final int addressId;
  final String label;
  final String fullAddress;
  final String? phone;
  final bool isDefault;

  const AddressModel({
    required this.addressId,
    required this.label,
    required this.fullAddress,
    this.phone,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        addressId: (json['addressId'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        fullAddress: json['fullAddress'] as String? ?? '',
        phone: json['phone'] as String?,
        isDefault: json['isDefault'] == '1' || json['isDefault'] == true,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'fullAddress': fullAddress,
        if (phone != null) 'phone': phone,
        'isDefault': isDefault ? '1' : '0',
      };
}
