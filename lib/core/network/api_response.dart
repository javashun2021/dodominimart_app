/// Wraps the RuoYi AjaxResult format:
/// { "code": 200, "msg": "操作成功", "data": {...} }
class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;

  const ApiResponse({required this.code, required this.msg, this.data});

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromData,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? 0,
      msg: json['msg'] as String? ?? '',
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : null,
    );
  }
}

/// Wraps RuoYi paginated list format:
/// { "code": 200, "rows": [...], "total": 100 }
class ApiListResponse<T> {
  final int code;
  final String msg;
  final List<T> rows;
  final int total;

  const ApiListResponse({
    required this.code,
    required this.msg,
    required this.rows,
    required this.total,
  });

  bool get isSuccess => code == 200;

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    return ApiListResponse<T>(
      code: json['code'] as int? ?? 0,
      msg: json['msg'] as String? ?? '',
      rows: rawRows.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
