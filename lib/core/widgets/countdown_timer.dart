import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;
  final bool showLabel;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.style,
    this.showLabel = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.endTime.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Text(
        'Ended',
        style: widget.style ??
            const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
      );
    }

    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final text = widget.showLabel ? 'Ends in $h:$m:$s' : '$h:$m:$s';

    return Text(
      text,
      style: widget.style ??
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}
