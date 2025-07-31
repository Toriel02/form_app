import 'package:flutter/material.dart';
import 'package:form_app/styles/styles.dart';

PreferredSizeWidget buildAppBar(String title, VoidCallback onLogout) {
  return AppBar(
    title: Text(title, style: AppTextStyles.appBarTitle),
    centerTitle: true,
    backgroundColor: AppColors.primary,
    elevation: 6,
    actions: [
      IconButton(
        icon: const Icon(Icons.logout, color: AppColors.logoutIcon),
        onPressed: onLogout,
        tooltip: 'Cerrar Sesión',
      ),
    ],
  );
}