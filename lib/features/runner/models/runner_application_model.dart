import '../../../core/constants/api_endpoints.dart';

class RunnerApplicationModel {
  final int? appId;
  final String status; // "none"|"0"=待审|"1"=通过|"2"=拒绝
  final String? realName;
  final String? idNumber;
  final String? phone;
  final String? idPhotoUrl;
  final String? rejectReason;
  final DateTime? applyTime;
  final bool isOnline;

  const RunnerApplicationModel({
    this.appId,
    required this.status,
    this.realName,
    this.idNumber,
    this.phone,
    this.idPhotoUrl,
    this.rejectReason,
    this.applyTime,
    this.isOnline = false,
  });

  bool get isNone     => status == 'none';
  bool get isPending  => status == '0';
  bool get isApproved => status == '1';
  bool get isRejected => status == '2';

  String? get resolvedIdPhoto => ApiEndpoints.resolveImage(idPhotoUrl);

  factory RunnerApplicationModel.none() =>
      const RunnerApplicationModel(status: 'none');

  factory RunnerApplicationModel.fromJson(Map<String, dynamic> json) =>
      RunnerApplicationModel(
        appId: (json['appId'] as num?)?.toInt(),
        status: json['status']?.toString() ?? '0',
        realName: json['realName'] as String?,
        idNumber: json['idNumber'] as String?,
        phone: json['phone'] as String?,
        idPhotoUrl: json['idPhotoUrl'] as String?,
        rejectReason: json['rejectReason'] as String?,
        applyTime: json['applyTime'] != null
            ? DateTime.tryParse(json['applyTime'] as String)
            : null,
        isOnline: json['isOnline'] == '1' || json['isOnline'] == true,
      );
}
