import 'package:flutter/material.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? labelColor;
  final Color? iconColor;

  const CommonChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.color,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        color ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final effectiveLabelColor =
        labelColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Material(
        color: effectiveColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: effectiveIconColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveLabelColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
