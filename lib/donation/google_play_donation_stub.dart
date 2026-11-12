import 'package:flutter/material.dart';

/// Stub for F-Droid / open-source builds.
/// Replaces google_play_donation.dart during CI when GOOGLE_PLAY is false.
///
/// The real file imports `package:in_app_purchase` which F-Droid must not
/// include, so this stub provides the same public API with no-op returns.
class GooglePlayDonation {
  static Future<Widget?> buildIapButtons(BuildContext context) async {
    return null;
  }
}
