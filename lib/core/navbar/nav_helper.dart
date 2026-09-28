import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/routes/app_routes.dart';

/// Navigation utility that routes through the tab navigator when inside
/// the navbar scaffold, falling back to root navigation otherwise.
class NavHelper {
  NavHelper._();

  static NavbarController? get _controller =>
      Get.isRegistered<NavbarController>() ? Get.find<NavbarController>() : null;

  /// Push a screen onto the current tab's navigator.
  /// Falls back to root navigator if navbar is not active.
  /// Returns a [Future] that completes when the pushed screen is popped.
  static Future<void> push(Widget screen) async {
    final c = _controller;
    if (c != null) {
      await c.navigateInCurrentTab(screen);
    } else {
      await Get.to(() => screen);
    }
  }

  /// Replace the top route in the current tab's navigator.
  static void pushReplacement(Widget screen) {
    final c = _controller;
    if (c != null) {
      c.replaceInCurrentTab(screen);
    } else {
      Get.off(() => screen);
    }
  }

  /// Pop the current tab's navigator.
  static void pop() {
    final c = _controller;
    if (c != null && c.canPopCurrentTab()) {
      c.popCurrentTab();
    } else {
      Get.back();
    }
  }

  /// Pop the current tab to its root screen.
  static void popToRoot() {
    final c = _controller;
    if (c != null) {
      c.popToRootCurrentTab();
    }
  }

  /// Switch to a tab (and pop it to root).
  static void switchTab(int index) {
    final c = _controller;
    if (c != null) {
      c.changeIndex(index);
    }
  }

  /// Pop everything the root navigator holds above the tab shell, and report
  /// whether the shell is what's on screen afterwards.
  ///
  /// It may not be in the stack at all — a cold start still on the splash, or
  /// a signed-out session — in which case there is nothing to return to.
  static bool returnToShell() {
    if (Get.currentRoute != AppRoutes.navbarScreen) {
      // `isFirst` is the floor: a predicate that matches nothing pops the root
      // navigator empty.
      Get.until((route) =>
          route.settings.name == AppRoutes.navbarScreen || route.isFirst);
    }
    return Get.currentRoute == AppRoutes.navbarScreen;
  }

  /// Bring the shell back to the front and open [screen] inside [tab].
  ///
  /// A screen pushed straight onto the root navigator covers the shell, so it
  /// loses the bottom bar — and anything it pushes in turn through [push]
  /// lands on a tab navigator hidden behind it, which reads as a tap doing
  /// nothing at all. So everything opened from outside the shell — a tapped
  /// push notification, the request-sent screen — comes in through here.
  static Future<void> openInTab(int tab, Widget screen) async {
    final c = _controller;
    if (c == null || !returnToShell()) {
      // No shell to open inside. A plain root push at least gets the customer
      // to the screen they asked for.
      await Get.to(() => screen);
      return;
    }
    c.changeIndex(tab);
    await c.navigateInCurrentTab(screen);
  }
}
