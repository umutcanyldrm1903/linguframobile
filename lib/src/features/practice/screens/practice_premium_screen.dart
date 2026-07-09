import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_ad_service.dart';
import '../practice_api_service.dart';
import '../practice_purchase_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticePremiumScreen extends StatefulWidget {
  const PracticePremiumScreen({super.key});

  @override
  State<PracticePremiumScreen> createState() => _PracticePremiumScreenState();
}

class _PracticePremiumScreenState extends State<PracticePremiumScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final PracticePurchaseService _purchase = PracticePurchaseService();
  final PracticeAdService _ads = PracticeAdService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Map<String, dynamic> _status = {};
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _buying = false;
  bool _rewarding = false;
  bool _checkingStore = false;
  bool _routeArgumentsRead = false;
  String? _offerTitle;
  String? _offerSubtitle;
  String? _storeQueryMessage;

  @override
  void initState() {
    super.initState();
    _purchaseSub = _purchase.purchaseStream.listen(_handlePurchases);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgumentsRead) return;
    _routeArgumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final title = '${arguments['title'] ?? ''}'.trim();
      final subtitle = '${arguments['subtitle'] ?? ''}'.trim();
      _offerTitle = title.isEmpty ? null : title;
      _offerSubtitle = subtitle.isEmpty ? null : subtitle;
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showStoreFeedback = false}) async {
    setState(() => _loading = true);
    final status = await _api.getPremiumStatus();
    final products = await _purchase.loadProducts();
    final storeMessage = _purchase.lastPremiumQueryMessage;
    if (!mounted) return;
    setState(() {
      _status = status ?? _fallbackStatus();
      _products = products
        ..sort((a, b) {
          if (a.id == PracticePurchaseService.yearlyId) return -1;
          if (b.id == PracticePurchaseService.yearlyId) return 1;
          return a.rawPrice.compareTo(b.rawPrice);
        });
      _storeQueryMessage = storeMessage;
      _loading = false;
    });

    if (showStoreFeedback && mounted) {
      _showStoreStatus(
        storeMessage ?? 'Store bağlantısı kontrol edildi.',
      );
    }
  }

  Future<void> _showStoreStatus(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store bağlantı sonucu'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStoreConnection() async {
    if (_checkingStore) return;
    setState(() => _checkingStore = true);

    List<ProductDetails> products = [];
    String message;

    try {
      products = await _purchase.loadProducts();
      products.sort((a, b) {
        if (a.id == PracticePurchaseService.yearlyId) return -1;
        if (b.id == PracticePurchaseService.yearlyId) return 1;
        return a.rawPrice.compareTo(b.rawPrice);
      });
      message = _purchase.lastPremiumQueryMessage ??
          (products.isEmpty
              ? 'Store bağlantısı kontrol edildi ama ürün dönmedi.'
              : '${products.length} premium ürünü App Store’dan geldi.');
    } on Object catch (error) {
      message = 'Store bağlantısı kontrol edilemedi: $error';
    }

    if (!mounted) return;
    setState(() {
      _products = products;
      _storeQueryMessage = message;
      _checkingStore = false;
    });

    final detail = [
      message,
      '',
      'Beklenen ürün kimlikleri:',
      ...PracticePurchaseService.productIds.map((id) => '• $id'),
      if (products.isNotEmpty) ...[
        '',
        'App Store’dan gelen ürünler:',
        ...products.map((product) => '• ${product.id} - ${product.price}'),
      ],
    ].join('\n');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store bağlantı sonucu'),
        content: SingleChildScrollView(child: Text(detail)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final result = await _purchase.verifyPurchase(purchase);
        if (result?['verified'] == true) {
          await PracticeSoundService.playComplete();
          await _load();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result?['message'] ?? 'Satın alma mağaza tarafından doğrulanamadı.'}',
              ),
            ),
          );
        }
      } else if (purchase.status == PurchaseStatus.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              purchase.error?.message ?? 'Satın alma tamamlanamadı.',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _buying = false);
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() => _buying = true);
    final started = await _purchase.buy(product);
    if (!started && mounted) {
      setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _purchase.lastPremiumQueryMessage ?? 'Satın alma başlatılamadı.',
          ),
        ),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _buying = true);
    await _purchase.restorePurchases();
    if (mounted) setState(() => _buying = false);
  }

  Future<void> _rewardedAd() async {
    setState(() => _rewarding = true);
    final premium = _status['is_premium'] == true;
    final ok = await _ads.showRewarded(
      rewardType: 'coin',
      premium: premium,
      placement: 'practice_shop',
    );
    if (mounted) {
      setState(() => _rewarding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Reklam ödülü hesabına kaydedildi.'
              : 'Reklam gösterilemedi veya Premium aktif.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = _status['is_premium'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Premium',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Premium yükleniyor...'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                PracticeConfettiOverlay(
                  active: premium,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: premium
                          ? const Color(0xFFE8FBE2)
                          : const Color(0xFFE8F7FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: premium
                            ? const Color(0xFFB6F09A)
                            : const Color(0xFFC7EBFF),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        PracticeMascot(
                          size: 110,
                          mood: premium
                              ? PracticeMascotMood.excited
                              : PracticeMascotMood.proud,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                premium
                                    ? 'Premium aktif'
                                    : (_offerTitle ??
                                        'Premium ile kesintisiz ilerle'),
                                style: const TextStyle(
                                  color: practiceInk,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                premium
                                    ? 'Sınırsız can, reklamsız pratik ve AI avantajları aktif.'
                                    : (_offerSubtitle ??
                                        'Sınırsız can, reklamsız pratik, AI açıklamaları ve gelişmiş tekrar modları.'),
                                style: const TextStyle(
                                  color: practiceMuted,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _SubscriptionLegalLinks(compact: true),
                const SizedBox(height: 18),
                _FeatureGrid(premium: premium),
                const SizedBox(height: 20),
                const Text(
                  'Paketler',
                  style: TextStyle(
                    color: practiceInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (_products.isEmpty)
                  _StoreSetupCard(
                    message: _storeQueryMessage,
                    checking: _checkingStore,
                    onCheck: _checkStoreConnection,
                  )
                else
                  for (final product in _products)
                    _ProductCard(
                      product: product,
                      recommended:
                          product.id == PracticePurchaseService.yearlyId,
                      busy: _buying,
                      onBuy: () => _buy(product),
                    ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _buying ? null : () => _restore(),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('SATIN ALMALARI GERİ YÜKLE'),
                ),
                const SizedBox(height: 18),
                _AdRewardCard(
                  loading: _rewarding,
                  premium: premium,
                  onTap: () => _rewardedAd(),
                ),
                const SizedBox(height: 14),
                const _SubscriptionLegalLinks(),
              ],
            ),
    );
  }

  Map<String, dynamic> _fallbackStatus() {
    return {
      'is_premium': false,
      'plan': null,
      'expires_at': null,
    };
  }
}

class _SubscriptionLegalLinks extends StatelessWidget {
  const _SubscriptionLegalLinks({this.compact = false});

  final bool compact;

  Future<void> _open(String path) async {
    final uri = Uri.parse('${AppConfig.webBaseUrl}$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE8A3), width: 1.5),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
            const Text(
              'Yasal bilgiler:',
              style: TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w900,
              ),
            ),
            InkWell(
              onTap: () => _open('/mobile-app-terms-of-use'),
              child: const Text(
                'Kullanım Şartları',
                style: TextStyle(
                  color: practiceBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            InkWell(
              onTap: () => _open('/mobile-app-privacy-policy'),
              child: const Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  color: practiceBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abonelik bilgileri',
            style: TextStyle(
              color: practiceInk,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Premium paketler App Store hesabın üzerinden yönetilir ve seçilen süreye göre otomatik yenilenir. İptal işlemini App Store abonelik ayarlarından yapabilirsin.',
            style: TextStyle(
              color: practiceMuted,
              height: 1.35,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => _open('/mobile-app-terms-of-use'),
                child: const Text('Kullanım Şartları'),
              ),
              TextButton(
                onPressed: () => _open('/mobile-app-privacy-policy'),
                child: const Text('Gizlilik Politikası'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.favorite_rounded, 'Sınırsız can', 'Yanlış cevapta durma'),
      (Icons.block_rounded, 'Reklamsız', 'Ders sonrası kesinti yok'),
      (Icons.psychology_rounded, 'AI açıklama', 'Neden yanlış olduğunu sor'),
      (Icons.mic_rounded, 'Konuşma+', 'Gelişmiş telaffuz akışı'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: practiceLine, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                item.$1,
                color: premium ? practiceGreen : practiceBlue,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: practiceInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: practiceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.recommended,
    required this.busy,
    required this.onBuy,
  });

  final ProductDetails product;
  final bool recommended;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final title = product.title.split('(').first.trim();
    final isSubscription = product.id != PracticePurchaseService.lifetimeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? const Color(0xFFF1F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: recommended ? practiceBlue : practiceLine,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: practiceBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? product.title : title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (recommended)
                  const Text(
                    'EN AVANTAJLI PAKET',
                    style: TextStyle(
                      color: practiceBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isSubscription) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.card_giftcard_rounded,
                          color: practiceGreen, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Koşulları App Store ekranında gör',
                        style: TextStyle(
                          color: practiceGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: busy ? null : onBuy,
            child: Text(product.price),
          ),
        ],
      ),
    );
  }
}

class _StoreSetupCard extends StatelessWidget {
  const _StoreSetupCard({
    required this.onCheck,
    required this.checking,
    this.message,
  });

  final VoidCallback onCheck;
  final bool checking;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE08A), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message == null
                ? 'Store ürünleri bekleniyor'
                : 'Store bağlantısı kontrol edildi',
            style: TextStyle(
              color: practiceInk,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                'App Store tarafında ürün kimlikleri tanımlanınca paketler burada otomatik görünecek.',
            style: TextStyle(
              color: practiceMuted,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PracticePurchaseService.productIds
                .map((id) => Chip(label: Text(id)))
                .toList(),
          ),
          const SizedBox(height: 8),
          if (checking) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: checking ? null : onCheck,
            child: const Text('STORE BAĞLANTISINI KONTROL ET'),
          ),
        ],
      ),
    );
  }
}

class _AdRewardCard extends StatelessWidget {
  const _AdRewardCard({
    required this.loading,
    required this.premium,
    required this.onTap,
  });

  final bool loading;
  final bool premium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              color: practiceOrange, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              premium
                  ? 'Premium aktif olduğu için reklam gösterilmez.'
                  : 'Rewarded reklam izleyerek coin/can ödülü kazan.',
              style: const TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: loading || premium ? null : onTap,
            child: Text(loading ? '...' : 'DENE'),
          ),
        ],
      ),
    );
  }
}
