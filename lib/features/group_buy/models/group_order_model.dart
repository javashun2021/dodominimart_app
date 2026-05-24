import '../../../core/constants/api_endpoints.dart';
import 'group_activity_model.dart';

class GroupMember {
  final String nickName;
  final String? avatarUrl;
  final int quantity;

  const GroupMember({
    required this.nickName,
    this.avatarUrl,
    required this.quantity,
  });

  String? get resolvedAvatar => ApiEndpoints.resolveImage(avatarUrl);

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        nickName: json['nickName'] as String? ?? 'Member',
        avatarUrl: json['avatarUrl'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

class GroupOrderModel {
  final int groupOrderId;
  final String inviteCode;
  final int? initiatorMemberId;
  final String activityTitle;
  final String productName;
  final String? productImage;
  final int currentSize;
  final int minGroupSize;
  final double currentPrice;
  final double? originalPrice;
  final DateTime expireTime;
  final String status; // "0"=open "1"=success "2"=failed
  final List<GroupMember> members;
  final List<PriceTier> tiers;
  final String? orderId; // 成团后生成的订单ID

  const GroupOrderModel({
    required this.groupOrderId,
    required this.inviteCode,
    this.initiatorMemberId,
    required this.activityTitle,
    required this.productName,
    this.productImage,
    required this.currentSize,
    required this.minGroupSize,
    required this.currentPrice,
    this.originalPrice,
    required this.expireTime,
    required this.status,
    required this.members,
    required this.tiers,
    this.orderId,
  });

  bool get isOpen => status == '0';
  bool get isSuccess => status == '1';
  bool get isFailed => status == '2';
  int get remaining => (minGroupSize - currentSize).clamp(0, minGroupSize);

  String? get resolvedProductImage =>
      ApiEndpoints.resolveImage(productImage);

  factory GroupOrderModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final activity = data['activity'] as Map<String, dynamic>? ?? {};
    return GroupOrderModel(
      groupOrderId: (data['groupOrderId'] as num?)?.toInt() ?? 0,
      inviteCode: data['inviteCode'] as String? ?? '',
      initiatorMemberId: (data['initiatorMemberId'] as num?)?.toInt(),
      activityTitle: activity['title'] as String? ?? '',
      productName: activity['productName'] as String? ?? '',
      productImage: activity['productImage'] as String?,
      currentSize: (data['currentSize'] as num?)?.toInt() ?? 0,
      minGroupSize: (activity['minGroupSize'] as num?)?.toInt() ?? 2,
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (activity['originalPrice'] as num?)?.toDouble(),
      expireTime: _parseDate(data['expireTime']),
      status: data['status']?.toString() ?? '0',
      members: (data['members'] as List<dynamic>? ?? [])
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      tiers: (activity['tiers'] as List<dynamic>? ?? [])
          .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderId: data['orderId']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(hours: 24));
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now().add(const Duration(hours: 24));
    }
    return DateTime.now().add(const Duration(hours: 24));
  }
}
