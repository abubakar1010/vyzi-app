import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom-nav positions, named because deep links address them.
///
/// The tab a notification opens is decided in NotificationRouter, a long way
/// from the bar that renders these, and `switchTab(1)` there said nothing
/// about where it lands.
class NavTabs {
  NavTabs._();

  static const int home = 0;
  static const int request = 1;
  static const int utilities = 2;
  static const int profile = 3;
}

class NavbarController extends GetxController {
  final _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;

  /// Reactive stream for tab change listeners (e.g. data refresh on tab switch)
  RxInt get selectedTabRx => _selectedIndex;

  /// One GlobalKey<NavigatorState> per tab
  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  GlobalKey<NavigatorState> get currentNavigatorKey =>
      navigatorKeys[_selectedIndex.value];

  void changeIndex(int index) {
    // Always pop the target tab to its root screen
    navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    _selectedIndex.value = index;
  }

  /// Push a screen onto the current tab's navigator
  Future<void> navigateInCurrentTab(Widget screen) async {
    await currentNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Push replacement onto the current tab's navigator
  void replaceInCurrentTab(Widget screen) {
    currentNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Whether the current tab's navigator can pop
  bool canPopCurrentTab() {
    return currentNavigatorKey.currentState?.canPop() ?? false;
  }

  /// Pop the current tab's navigator
  void popCurrentTab() {
    currentNavigatorKey.currentState?.pop();
  }

  /// Pop the current tab's navigator to its root
  void popToRootCurrentTab() {
    currentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
