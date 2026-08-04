// ignore_for_file: unused_import
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'flavor.dart';

/// Stub for F-Droid / open-source builds.
/// Replaces google_play_donation.dart during CI when GOOGLE_PLAY is false.
///
/// The real file imports `package:in_app_purchase` which F-Droid must not
/// include, so this stub provides the same public API with no-op returns.
class GooglePlayDonation {
  GooglePlayDonation(BuildContext _) {}

  void init(void Function(List<dynamic>) onPurchase) {}
  void dispose() {}

  static Future<Widget?> buildIapButtons(BuildContext context) async {
    return null;
  }

  static Future<void> completePurchase(dynamic purchase) async {}
}
