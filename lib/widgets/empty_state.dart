import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            ),
            child: Icon(icon, size: 44,
                color: isDark ? Colors.white24 : Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.grey.shade500)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
