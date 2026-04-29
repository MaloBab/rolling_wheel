// lib/presentation/widgets/layout/sg_snackbar.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

void showSgSnackbar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? kAccent4 : kAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}