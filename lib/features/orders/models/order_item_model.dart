class OrderItemModel {
  final String productId;
  final String productName;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final String unit;
  final double subtotal;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName'] as String? ?? '',
        productImageUrl: json['productImage'] as String? ??
            json['productImageUrl'] as String?,
        unitPrice: (json['price'] as num?)?.toDouble() ??
            (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unit: json['unit'] as String? ?? 'piece',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'unit': unit,
        'subtotal': subtotal,
      };
}
