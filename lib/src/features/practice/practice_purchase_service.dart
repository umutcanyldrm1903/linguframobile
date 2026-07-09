import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'practice_api_service.dart';

class _StoreProductQueryResult {
  const _StoreProductQueryResult({
    required this.products,
    required this.notFoundIds,
    this.error,
  });

  final List<ProductDetails> products;
  final Set<String> notFoundIds;
  final IAPError? error;
}

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
  String? lastPremiumQueryMessage;
  String? lastGemQueryMessage;

  bool get _storeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  InAppPurchase? get _iap => _storeSupported ? InAppPurchase.instance : null;

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

  Future<bool> get isAvailable async {
    try {
      return await _iap?.isAvailable().timeout(const Duration(seconds: 8)) ??
          false;
    } on Object {
      return false;
    }
  }

  bool _isTransientStoreKitFailure(Object? error) {
    final text = error.toString().toLowerCase();
    return error is PlatformException ||
        text.contains('storekit') ||
        text.contains('failed to get response from platform') ||
        text.contains('platform') ||
        text.contains('unavailable') ||
        text.contains('timed out') ||
        text.contains('timeout');
  }

  bool _isTransientResponseError(ProductDetailsResponse response) {
    final message = response.error?.message.toLowerCase() ?? '';
    final code = response.error?.code.toLowerCase() ?? '';
    return message.contains('failed to get response from platform') ||
        message.contains('storekit') ||
        message.contains('platform') ||
        message.contains('unavailable') ||
        message.contains('timed out') ||
        message.contains('timeout') ||
        code.contains('storekit') ||
        code.contains('platform') ||
        code.contains('unavailable');
  }

  String _friendlyStoreFailure() {
    return 'App Store şu anda ürün listesini cevaplamadı. Birkaç saniye sonra tekrar dene. '
        'Devam ederse App Store oturumunu, TestFlight/App Store sürümünü ve internet bağlantını kontrol et.';
  }

  Future<ProductDetailsResponse> _queryProductDetailsWithRetry(
    InAppPurchase iap,
    Set<String> ids,
  ) async {
    Object? lastError;
    ProductDetailsResponse? lastResponse;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await iap
            .queryProductDetails(ids)
            .timeout(const Duration(seconds: 10));
        lastResponse = response;
        if (response.error == null || !_isTransientResponseError(response)) {
          return response;
        }
      } on Object catch (error) {
        lastError = error;
        if (!_isTransientStoreKitFailure(error)) rethrow;
      }

      if (attempt < 2) {
        await Future<void>.delayed(
          Duration(milliseconds: 700 * (attempt + 1)),
        );
      }
    }

    if (lastResponse != null) return lastResponse;
    throw lastError ?? StateError('StoreKit ürün sorgusu cevap vermedi.');
  }

  Future<_StoreProductQueryResult> _queryProductsResilient(
    InAppPurchase iap,
    Set<String> ids,
  ) async {
    ProductDetailsResponse? response;

    try {
      response = await _queryProductDetailsWithRetry(iap, ids);
      if (response.error == null ||
          response.productDetails.isNotEmpty ||
          ids.length == 1) {
        return _StoreProductQueryResult(
          products: response.productDetails.toList(),
          notFoundIds: response.notFoundIDs.toSet(),
          error: response.error,
        );
      }
    } on Object {
      if (ids.length == 1) rethrow;
    }

    final products = <ProductDetails>[];
    final notFoundIds = <String>{};
    var lastError = response?.error;

    for (final id in ids) {
      try {
        final singleResponse = await _queryProductDetailsWithRetry(iap, {id});
        products.addAll(singleResponse.productDetails);
        notFoundIds.addAll(singleResponse.notFoundIDs);
        lastError = singleResponse.error ?? lastError;
        if (singleResponse.productDetails.isEmpty &&
            singleResponse.notFoundIDs.isEmpty) {
          notFoundIds.add(id);
        }
      } on Object {
        notFoundIds.add(id);
      }
    }

    return _StoreProductQueryResult(
      products: products,
      notFoundIds: notFoundIds,
      error: products.isEmpty ? lastError : null,
    );
  }

  Future<List<ProductDetails>> loadProducts() async {
    try {
      final iap = _iap;
      if (iap == null) {
        lastPremiumQueryMessage =
            'Bu platformda App Store / Play Store satın alma desteklenmiyor.';
        return [];
      }

      final available =
          await iap.isAvailable().timeout(const Duration(seconds: 8));
      if (!available) {
        lastPremiumQueryMessage =
            'Store bağlantısı şu anda kullanılamıyor. Cihazda App Store hesabı, internet ve uygulama imzası kontrol edilmeli.';
        return [];
      }

      final query = await _queryProductsResilient(iap, productIds);
      final products = query.products
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

      if (query.error != null && products.isEmpty) {
        lastPremiumQueryMessage =
            'Store hata döndürdü: ${query.error!.message}. Tek tek ürün sorgusu da sonuç vermedi. Beklenen ürün ID: ${productIds.join(', ')}';
      } else if (products.isEmpty) {
        final missing = query.notFoundIds.isEmpty
            ? productIds.join(', ')
            : query.notFoundIds.join(', ');
        lastPremiumQueryMessage =
            'Store bağlantısı var ama ürün dönmedi. Eksik ürün ID: $missing. App Store Connect ürünleri onaylı olsa bile Paid Apps Agreement, Tax/Banking, bundle ID veya App Store yayılımı kontrol edilmeli.';
      } else if (query.notFoundIds.isNotEmpty) {
        lastPremiumQueryMessage =
            '${products.length} ürün geldi, şu ID’ler bulunamadı: ${query.notFoundIds.join(', ')}';
      } else {
        lastPremiumQueryMessage =
            '${products.length} premium ürün App Store’dan başarıyla geldi.';
      }

      return products;
    } on Object catch (error) {
      lastPremiumQueryMessage = _isTransientStoreKitFailure(error)
          ? _friendlyStoreFailure()
          : 'Store ürün sorgusu başarısız: $error';
      return [];
    }
  }

  Future<bool> buy(ProductDetails product) async {
    try {
      final iap = _iap;
      if (iap == null ||
          !await iap.isAvailable().timeout(const Duration(seconds: 8))) {
        lastPremiumQueryMessage =
            'Store bağlantısı şu anda kullanılamıyor. App Store hesabını ve internet bağlantını kontrol et.';
        return false;
      }
      final param = PurchaseParam(productDetails: product);
      if (product.id == lifetimeId) {
        return iap.buyNonConsumable(purchaseParam: param);
      }
      return iap.buyNonConsumable(purchaseParam: param);
    } on Object catch (error) {
      lastPremiumQueryMessage = _isTransientStoreKitFailure(error)
          ? _friendlyStoreFailure()
          : 'Satın alma başlatılamadı: $error';
      return false;
    }
  }

  /// Mücevher paketleri (consumable). Store'da ürün tanımlı değilse, billing
  /// kullanılamıyorsa (emülatör / Play Services yok) veya hata olursa boş döner
  /// — mağaza ekranı asla çökmemeli.
  Future<List<ProductDetails>> loadGemProducts() async {
    try {
      final iap = _iap;
      if (iap == null) {
        lastGemQueryMessage =
            'Bu platformda App Store / Play Store satın alma desteklenmiyor.';
        return [];
      }
      if (!await iap.isAvailable().timeout(const Duration(seconds: 8))) {
        lastGemQueryMessage =
            'Store bağlantısı şu anda kullanılamıyor. Cihazda App Store hesabı, internet ve uygulama imzası kontrol edilmeli.';
        return [];
      }
      final query = await _queryProductsResilient(iap, gemProductIds);
      final products = query.products
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

      if (query.error != null && products.isEmpty) {
        lastGemQueryMessage =
            'Store hata döndürdü: ${query.error!.message}. Tek tek mücevher sorgusu da sonuç vermedi. Beklenen ürün ID: ${gemProductIds.join(', ')}';
      } else if (products.isEmpty) {
        final missing = query.notFoundIds.isEmpty
            ? gemProductIds.join(', ')
            : query.notFoundIds.join(', ');
        lastGemQueryMessage =
            'Store bağlantısı var ama mücevher ürünü dönmedi. Eksik ürün ID: $missing.';
      } else if (query.notFoundIds.isNotEmpty) {
        lastGemQueryMessage =
            '${products.length} mücevher ürünü geldi, şu ID’ler bulunamadı: ${query.notFoundIds.join(', ')}';
      } else {
        lastGemQueryMessage =
            '${products.length} mücevher ürünü App Store’dan başarıyla geldi.';
      }

      return products;
    } on Object catch (error) {
      lastGemQueryMessage = _isTransientStoreKitFailure(error)
          ? _friendlyStoreFailure()
          : 'Store mücevher sorgusu başarısız: $error';
      return [];
    }
  }

  /// Consumable (tekrar alınabilir) satın alma — mücevher paketleri için.
  Future<bool> buyConsumable(ProductDetails product) async {
    try {
      final iap = _iap;
      if (iap == null ||
          !await iap.isAvailable().timeout(const Duration(seconds: 8))) {
        lastGemQueryMessage =
            'Store bağlantısı şu anda kullanılamıyor. App Store hesabını ve internet bağlantını kontrol et.';
        return false;
      }
      return iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } on Object catch (error) {
      lastGemQueryMessage = _isTransientStoreKitFailure(error)
          ? _friendlyStoreFailure()
          : 'Mücevher satın alma başlatılamadı: $error';
      return false;
    }
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
    try {
      final iap = _iap;
      if (iap != null) {
        await iap.restorePurchases().timeout(const Duration(seconds: 12));
      }
    } on Object catch (error) {
      lastPremiumQueryMessage = _isTransientStoreKitFailure(error)
          ? _friendlyStoreFailure()
          : 'Satın almalar geri yüklenemedi: $error';
    }
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
