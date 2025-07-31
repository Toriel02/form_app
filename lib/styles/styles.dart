import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F7FA);
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const cardShadow = Color(0xFF0D47A1);
  static const logoutIcon = Colors.white;

  // Otros colores usados en cards o botones
  static const cardBlue = Color(0xFF42A5F5);
  static const cardCyan = Color(0xFF26C6DA);
  static const cardGreen = Color(0xFF66BB6A);
  static const cardPurple = Color(0xFFAB47BC);
  static const cardOrange = Color(0xFFFF7043);
}

class AppTextStyles {
  static const appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static const headline = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: Color(0xFF0D47A1),
  );

  static const body = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
}

class AppDecorations {
  static BoxDecoration cardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration panelDecoration = BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
}