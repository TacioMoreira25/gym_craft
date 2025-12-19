import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final Color? titleColor;

  const AppDialog({
    Key? key,
    required this.title,
    required this.content,
    this.actions,
    this.titleColor,
  }) : super(key: key);

  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        titleColor: isDestructive ? Colors.red : null,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: (isDestructive || confirmColor != null)
                ? FilledButton.styleFrom(
                    backgroundColor: isDestructive ? Colors.red : confirmColor,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: titleColor ?? theme.colorScheme.onSurface,
        ),
      ),
      content: DefaultTextStyle(
        style: TextStyle(
          fontSize: 16,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        child: content,
      ),
      actions: actions,
    );
  }
}
