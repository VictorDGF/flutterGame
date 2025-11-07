import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AlertHelper {
  static void show({
    required String message,
    String title = '',
    required AlertType type,
  }) {
    final colors = _getColors(type);
    final icon = _getIcon(type);

    Get.snackbar(
      title.isEmpty ? _getTitle(type) : title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 18,
      duration: const Duration(seconds: 3),
      messageText: _buildContent(message, colors, icon),
      titleText: const SizedBox.shrink(),
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  static Widget _buildContent(String message, List<Color> colors, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> _getColors(AlertType type) {
    switch (type) {
      case AlertType.success:
        return [const Color(0xFF43A047), const Color(0xFF66BB6A)];
      case AlertType.error:
        return [const Color(0xFFD32F2F), const Color(0xFFEF5350)];
      case AlertType.warning:
        return [const Color(0xFFFFA000), const Color(0xFFFFCA28)];
      case AlertType.info:
        return [const Color(0xFF1976D2), const Color(0xFF64B5F6)];
    }
  }

  static IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  static String _getTitle(AlertType type) {
    switch (type) {
      case AlertType.success:
        return 'Éxito';
      case AlertType.error:
        return 'Error';
      case AlertType.warning:
        return 'Advertencia';
      case AlertType.info:
        return 'Información';
    }
  }

  /// Métodos de acceso rápido
  static void success(String message, {String title = ''}) =>
      show(message: message, title: title, type: AlertType.success);

  static void error(String message, {String title = ''}) =>
      show(message: message, title: title, type: AlertType.error);

  static void warning(String message, {String title = ''}) =>
      show(message: message, title: title, type: AlertType.warning);

  static void info(String message, {String title = ''}) =>
      show(message: message, title: title, type: AlertType.info);
}

enum AlertType { success, error, warning, info }
