import 'package:flutter/material.dart';

/// Utilitário para criar notificações consistentes com SnackBar
class SnackBarUtils {
  /// Configurações padrão de cores
  static const Color _successColor = Color(0xFF10B981); // Green-600
  static const Color _errorColor = Color(0xFFDC2626); // Red-600
  static const Color _warningColor = Color(0xFFF59E0B); // Amber-500
  static const Color _infoColor = Color(0xFF3B82F6); // Blue-500

  /// Configurações padrão de SnackBar
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 5);
  static const SnackBarBehavior _defaultBehavior = SnackBarBehavior.floating;
  static const EdgeInsets _defaultMargin = EdgeInsets.all(16);

  /// Mostra SnackBar de sucesso
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: _successColor,
      duration: duration ?? _defaultDuration,
      action: action,
    );
  }

  /// Mostra SnackBar de erro
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: _errorColor,
      duration: duration ?? _longDuration,
      action: action,
    );
  }

  /// Mostra SnackBar de aviso
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: _warningColor,
      duration: duration ?? _defaultDuration,
      action: action,
    );
  }

  /// Mostra SnackBar de informação
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: _infoColor,
      duration: duration ?? _defaultDuration,
      action: action,
    );
  }

  /// Mostra SnackBar customizado
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
    SnackBarBehavior? behavior,
    EdgeInsets? margin,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      duration: duration ?? _defaultDuration,
      action: action,
      behavior: behavior,
      margin: margin,
    );
  }

  /// Método interno para criar e mostrar SnackBar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
    SnackBarBehavior? behavior,
    EdgeInsets? margin,
  }) {
    // Remove SnackBar atual se existir
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? _defaultDuration,
        behavior: behavior ?? _defaultBehavior,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: margin ?? _defaultMargin,
        action: action,
      ),
    );
  }

  /// Mostra SnackBar de loading com CircularProgressIndicator
  static void showLoading(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _infoColor,
        duration: duration ?? const Duration(seconds: 10),
        behavior: _defaultBehavior,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: _defaultMargin,
      ),
    );
  }

  /// Remove SnackBar atual
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Métodos de conveniência para operações comuns

  /// Sucesso ao salvar
  static void showSaveSuccess(BuildContext context, [String? itemName]) {
    final message = itemName != null
        ? '$itemName salvo com sucesso!'
        : 'Salvo com sucesso!';
    showSuccess(context, message);
  }

  /// Sucesso ao excluir
  static void showDeleteSuccess(BuildContext context, [String? itemName]) {
    final message = itemName != null
        ? '$itemName excluído com sucesso!'
        : 'Excluído com sucesso!';
    showSuccess(context, message);
  }

  /// Sucesso ao criar
  static void showCreateSuccess(BuildContext context, [String? itemName]) {
    final message = itemName != null
        ? '$itemName criado com sucesso!'
        : 'Criado com sucesso!';
    showSuccess(context, message);
  }

  /// Sucesso ao atualizar
  static void showUpdateSuccess(BuildContext context, [String? itemName]) {
    final message = itemName != null
        ? '$itemName atualizado com sucesso!'
        : 'Atualizado com sucesso!';
    showSuccess(context, message);
  }

  /// Erro genérico de operação
  static void showOperationError(
    BuildContext context,
    String operation, [
    String? error,
  ]) {
    final message = error != null
        ? 'Erro ao $operation: $error'
        : 'Erro ao $operation';
    showError(context, message);
  }

  /// Erro de validação
  static void showValidationError(BuildContext context, [String? message]) {
    showError(
      context,
      message ?? 'Por favor, corrija os erros nos campos destacados',
    );
  }

  /// Aviso de item em uso (não pode ser excluído)
  static void showItemInUseWarning(BuildContext context, [String? itemName]) {
    final message = itemName != null
        ? 'Não é possível excluir $itemName pois está sendo usado'
        : 'Item não pode ser excluído pois está sendo usado';
    showWarning(context, message);
  }

  /// Informação sobre limite atingido
  static void showLimitReached(
    BuildContext context,
    String limitType,
    int limit,
  ) {
    showInfo(context, 'Limite de $limit $limitType atingido');
  }

  /// Ação cancelada pelo usuário
  static void showActionCancelled(BuildContext context, [String? action]) {
    final message = action != null ? '$action cancelado' : 'Ação cancelada';
    showInfo(context, message);
  }
}
