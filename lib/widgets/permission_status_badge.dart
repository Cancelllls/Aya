import 'package:flutter/material.dart';

class PermissionStatusBadge extends StatelessWidget {
  final bool isGranted;
  final String grantedLabel;
  final String requiredLabel;

  const PermissionStatusBadge({
    super.key,
    required this.isGranted,
    this.grantedLabel = 'Granted',
    this.requiredLabel = 'Required',
  });

  @override
  Widget build(BuildContext context) {
    final color = isGranted ? Colors.teal : Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isGranted ? grantedLabel : requiredLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
