import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geosmart/core/theme/app_colors.dart';
import 'package:geosmart/shared/widgets/glass_container.dart';

class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? confirmText; // Alias for confirmLabel
  final Color confirmColor;
  final bool isDanger;
  final IconData icon;
  final VoidCallback? onConfirm;

  const CustomConfirmDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmer',
    this.confirmText,
    this.confirmColor = AppColors.primary,
    this.isDanger = false,
    this.icon = LucideIcons.helpCircle,
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final displayConfirmLabel = confirmText ?? confirmLabel;
    final displayConfirmColor = isDanger ? AppColors.error : confirmColor;
    final displayIcon = isDanger ? LucideIcons.alertTriangle : icon;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: displayConfirmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(displayIcon, color: displayConfirmColor, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Annuler', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      if (onConfirm != null) onConfirm!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: displayConfirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(displayConfirmLabel, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showCustomConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String? confirmText,
  Color confirmColor = AppColors.primary,
  bool isDanger = false,
  IconData icon = LucideIcons.helpCircle,
  VoidCallback? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CustomConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmText: confirmText,
      confirmColor: confirmColor,
      isDanger: isDanger,
      icon: icon,
      onConfirm: onConfirm,
    ),
  );
}
