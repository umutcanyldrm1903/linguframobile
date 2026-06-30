import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'practice_api_service.dart';

class PracticePurchaseService {
  PracticePurchaseService({this.api = const PracticeApiService()});

  static const monthlyId = 'lingufranca_practice_premium_monthly';
  static const yearlyId = 'lingufranca_practice_premium_yearly';
  static const familyId = 'lingufranca_practice_premium_family';
  static const lifetimeId = 'lingufranca_practice_premium_lifetime';

  static const productIds = <String>{
    monthlyId,
    yearlyId,
    familyId,
    lifetimeId,
  };

  // Gerçek-paralı mücevher/coin paketleri (consumable IAP).
  static const gem1200Id = 'lingufranca_gems_1200';
  static const gem3000Id = 'lingufranca_gems_3000';
  static const gem6500Id = 'lingufranca_gems_6500';
  static const gem14000Id = 'lingufranca_gems_14000';

  static const gemProductIds = <String>{
    gem1200Id,
    gem3000Id,
    gem6500Id,
    gem14000Id,
  };

  final PracticeApiService api;

  bool get _storeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  InAppPurchase? get _iap =>
      _storeSupported ? InAppPurchase.instance : null;

  String _provider() =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'app_store' : 'play_store';

  String _planKey(String productId) {
    return switch (productId) {
      monthlyId => 'monthly',
      yearlyId => 'yearly',
      familyId => 'family',
      lifetimeId => 'lifetime',
      _ => 'premium',
    };
  }

  Map<String, dynamic> _verificationPayload(
    PurchaseDetails purchase, {
    String? planKey,
  }) {
    return {
      'provider': _provider(),
      if (planKey != null) 'plan_key': planKey,
      'product_id': purchase.productID,
      'purchase_token': purchase.verificationData.serverVerificationData,
      'transaction_id': purchase.purchaseID,
    };
  }

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap?.purchaseStream ?? const Stream<List<PurchaseDetails>>.empty();

  Future<bool> get isAvailable async => await _iap?.isAvailable() ?? false;

  Future<List<ProductDetails>> loadProducts() async {
    final iap = _iap;
    if (iap == null || !await iap.isAvailable()) return [];
    final response = await iap.queryProductDetails(productIds);
    return response.productDetails.toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  Future<bool> buy(ProductDetails product) async {
    final iap = _iap;
    if (iap == null || !await iap.isAvailable()) return false;
    final param = PurchaseParam(productDetails: product);
    if (product.id == lifetimeId) {
      return iap.buyNonConsumable(purchaseParam: param);
    }
    return iap.buyNonConsumable(purchaseParam: param);
  }

  /// Mücevher paketleri (consumable). Store'da ürün tanımlı değilse, billing
  /// kullanılamıyorsa (emülatör / Play Services yok) veya hata olursa boş döner
  /// — mağaza ekranı asla çökmemeli.
  Future<List<ProductDetails>> loadGemProducts() async {
    try {
      final iap = _iap;
      if (iap == null || !await iap.isAvailable()) return [];
      final response = await iap.queryProductDetails(gemProductIds);
      return response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } on Object {
      return [];
    }
  }

  /// Consumable (tekrar alınabilir) satın alma — mücevher paketleri için.
  Future<bool> buyConsumable(ProductDetails product) async {
    final iap = _iap;
    if (iap == null || !await iap.isAvailable()) return false;
    return iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Mücevher satın almasını sunucuda doğrula + coin'e çevir.
  Future<Map<String, dynamic>?> verifyGemPurchase(
      PurchaseDetails purchase) async {
    final result = await api.verifyGemPurchase(_verificationPayload(purchase));
    final iap = _iap;
    if (iap != null &&
        result?['success'] == true &&
        purchase.pendingCompletePurchase) {
      await iap.completePurchase(purchase);
    }
    return result;
  }

  Future<void> restorePurchases() async {
    final iap = _iap;
    if (iap != null) await iap.restorePurchases();
  }

  Future<Map<String, dynamic>?> verifyPurchase(PurchaseDetails purchase) async {
    final result = await api.verifyPremiumPurchase(
      _verificationPayload(
        purchase,
        planKey: _planKey(purchase.productID),
      ),
    );
    final iap = _iap;
    if (iap != null &&
        result?['verified'] == true &&
        purchase.pendingCompletePurchase) {
      await iap.completePurchase(purchase);
    }
    return result;
  }
}
