import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/routes/app_routes.dart';

/// GetX middleware that redirects unauthenticated users to sign-in.
/// Attach this to any route that requires a logged-in session.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final storage = Get.find<StorageService>();
    final isLoggedIn = storage.getBool(StorageKeys.isLoggedIn) ?? false;
    final token = storage.getString(StorageKeys.authToken);

    if (!isLoggedIn || token == null || token.isEmpty) {
      return RouteSettings(name: AppRoutes.signInScreen);
    }
    return null; // allow navigation
  }
}
