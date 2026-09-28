import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/legal/controller/legal_controller.dart';
import 'package:vyzi/features/legal/screens/terms_update_screen.dart';

/// Raises the consent prompt when the signed-in account owes an acceptance.
///
/// Hooked to the app shell rather than to sign-in, because every route into the
/// app converges there: a fresh login, a splash-screen session restore, a
/// silent token refresh, or a deep link. One hook covers all of them, and a
/// user who was already signed in when new terms were published is caught on
/// their next launch rather than their next login.
class LegalGate {
  LegalGate._();

  /// The gate is a full-screen route; opening a second one over it would leave
  /// a prompt stranded underneath after the first is accepted.
  static bool _showing = false;

  static LegalController get controller {
    if (Get.isRegistered<LegalController>()) {
      return Get.find<LegalController>();
    }
    return Get.put(LegalController(), permanent: true);
  }

  /// Checks for pending documents and, if there are any, blocks the app behind
  /// the acceptance prompt until they are accepted or the user signs out.
  ///
  /// Safe to call on every app-shell mount: the check is deduplicated in
  /// [LegalController.checkPending], and a failed check never raises the gate.
  static Future<void> enforce() async {
    if (_showing) return;

    final legal = controller;
    final pending = await legal.checkPending();
    if (!pending || _showing) return;

    _showing = true;
    try {
      // Root navigator: the prompt has to sit above the bottom bar and the
      // per-tab navigators, not inside whichever tab happened to be open.
      await Get.to<bool>(
        () => const TermsUpdateScreen(),
        fullscreenDialog: true,
        opaque: true,
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 320),
        preventDuplicates: true,
      );
    } finally {
      _showing = false;
    }

    // A version that changed while the prompt was open closes it early; the
    // freshly fetched document is then put straight back in front of the user.
    if (legal.requiresAction) {
      await enforce();
    }
  }

  /// Schedules [enforce] for after the current frame, so it can be called from
  /// `initState` without navigating during a build.
  static void enforceAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => enforce());
  }
}
