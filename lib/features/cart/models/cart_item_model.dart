import '../../catalog/models/product_model.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final String unit;

  const CartItemModel({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
  });

  double get subtotal => unitPrice * quantity;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        unit: unit,
      );

  factory CartItemModel.fromProduct(ProductModel product, {int quantity = 1}) =>
      CartItemModel(
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        unitPrice: product.price,
        quantity: quantity,
        unit: product.unit,
      );

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        productImageUrl: json['productImageUrl'] as String?,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        unit: json['unit'] as String,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'unit': unit,
      };
}
