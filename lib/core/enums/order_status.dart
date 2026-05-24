import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum OrderStatus {
  pending,
  confirmed,
  outForDelivery,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  String get value => switch (this) {
        OrderStatus.pending => 'pending',
        OrderStatus.confirmed => 'confirmed',
        OrderStatus.outForDelivery => 'out_for_delivery',
        OrderStatus.delivered => 'delivered',
        OrderStatus.cancelled => 'cancelled',
      };

  Color get color => switch (this) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.confirmed => AppColors.statusConfirmed,
        OrderStatus.outForDelivery => AppColors.statusOutForDelivery,
        OrderStatus.delivered => AppColors.statusDelivered,
        OrderStatus.cancelled => AppColors.statusCancelled,
      };

  // Supports both API numeric codes ("0"-"4") and legacy string values
  static OrderStatus fromValue(String value) => switch (value) {
        '1' || 'confirmed' => confirmed,
        '2' || 'out_for_delivery' => outForDelivery,
        '3' || 'delivered' => delivered,
        '4' || 'cancelled' => cancelled,
        _ => pending, // '0' or 'pending'
      };

  bool get isActive =>
      this == pending || this == confirmed || this == outForDelivery;
  bool get isFinal => this == delivered || this == cancelled;
  bool get canCancel => this == pending;
}
