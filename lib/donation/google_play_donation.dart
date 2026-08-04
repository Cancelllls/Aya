import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/translation_service.dart';
import 'flavor.dart';

/// Google Play in-app purchase donations.
/// Only compiled when `--dart-define=GOOGLE_PLAY=true`.
class GooglePlayDonation {
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final BuildContext context;

  GooglePlayDonation(this.context);

  void init(void Function(List<PurchaseDetails>) onPurchase) {
    if (!kIsGooglePlay) return;
    _subscription = InAppPurchase.instance.purchaseStream.listen(onPurchase);
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Build the IAP donation buttons shown inside the dialog.
  static Future<Widget?> buildIapButtons(BuildContext context) async {
    if (!kIsGooglePlay) return null;

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return null;

    try {
      final response = await InAppPurchase.instance.queryProductDetails({
        'support_donation_1',
        'support_donation_5',
        'support_donation_10',
        'support_donation_20',
        'support_donation_50',
      });

      final products = response.productDetails;
      if (products.isEmpty) return null;
      final productMap = {for (var p in products) p.id: p};

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[1.0, 5.0, 10.0, 20.0, 50.0].map((val) {
            final productId = 'support_donation_${val.toInt()}';
            final product = productMap[productId];
            final price = product?.price ?? '\$${val.toInt()}';
            final isAr = TranslationService.isArabic;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5C158),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (product != null) {
                    InAppPurchase.instance.buyConsumable(
                      purchaseParam: PurchaseParam(productDetails: product),
                    );
                  }
                },
                child: Text(
                  isAr ? "دعم بقيمة $price" : "Support $price",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }
  }
}
