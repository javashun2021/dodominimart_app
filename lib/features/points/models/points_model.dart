class PointsLogModel {
  final int logId;
  final int delta;
  final int balanceAfter;
  final int source; // 1=order 2=review 3=signup 4=redeem
  final String? remark;
  final DateTime? createTime;

  const PointsLogModel({
    required this.logId,
    required this.delta,
    required this.balanceAfter,
    required this.source,
    this.remark,
    this.createTime,
  });

  bool get isEarn => delta > 0;

  String get sourceLabel {
    switch (source) {
      case 1: return 'Order Completed';
      case 2: return 'Review Bonus';
      case 3: return 'Welcome Bonus';
      case 4: return 'Redeemed';
      default: return 'Points';
    }
  }

  factory PointsLogModel.fromJson(Map<String, dynamic> json) {
    return PointsLogModel(
      logId: (json['logId'] as num?)?.toInt() ?? 0,
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      source: (json['source'] as num?)?.toInt() ?? 0,
      remark: json['remark'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'].toString())
          : null,
    );
  }
}

class PointsModel {
  final int balance;
  final List<PointsLogModel> logs;

  const PointsModel({required this.balance, required this.logs});

  factory PointsModel.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'] as List<dynamic>? ?? [];
    return PointsModel(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      logs: rawLogs
          .map((e) => PointsLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
