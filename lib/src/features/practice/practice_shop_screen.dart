import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/motion/app_motion.dart';
import 'practice_api_service.dart';
import 'practice_purchase_service.dart';
import 'practice_repository.dart';
import 'practice_sound_service.dart';
import 'screens/practice_visuals.dart';

class PracticeShopScreen extends StatefulWidget {
  const PracticeShopScreen({super.key});

  @override
  State<PracticeShopScreen> createState() => _PracticeShopScreenState();
}

class _PracticeShopScreenState extends State<PracticeShopScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final PracticeRepository _repo = const PracticeRepository();
  final PracticePurchaseService _purchase = PracticePurchaseService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  List<Map<String, dynamic>> _items = [];
  List<ProductDetails> _gemProducts = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _buying = false;
  bool _gemBusy = false;
  String? _gemQueryMessage;

  @override
  void initState() {
    super.initState();
    _purchaseSub = _purchase.purchaseStream
        .listen(_handleGemPurchases, onError: (Object _) {});
    _load();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final shopData = await _api.getShop();
    final stats = await _repo.fetchStats();
    final gems = await _purchase.loadGemProducts();
    final gemMessage = _purchase.lastGemQueryMessage;
    if (!mounted) return;
    final raw = shopData?['items'] ?? shopData?['shop_items'];
    setState(() {
      _items = _asList(raw);
      if (_items.isEmpty) _items = _fallbackItems();
      _gemProducts = gems;
      _gemQueryMessage = gemMessage;
      _stats = {
        'coins': stats.coins,
        'hearts': stats.hearts,
        'streak': stats.streak,
        'xp_multiplier': stats.xpMultiplier,
      };
      _loading = false;
    });
  }

  /// Mücevher (consumable) satın alma akışı: doğrula → coin'e çevir → yenile.
  Future<void> _handleGemPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!PracticePurchaseService.gemProductIds.contains(purchase.productID)) {
        continue; // premium akışı premium ekranında işlenir
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final result = await _purchase.verifyGemPurchase(purchase);
        if (!mounted) continue;
        if (result?['success'] == true) {
          await PracticeSoundService.onBadgeEarned();
          await _load();
          if (!mounted) return;
          final msg =
              '${result?['message'] ?? 'Mücevherlerin hesabına eklendi!'}';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: practiceBlue,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Satın alma mağaza tarafından doğrulanamadı.'),
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
    if (mounted) setState(() => _gemBusy = false);
  }

  Future<void> _buyGem(ProductDetails product) async {
    setState(() => _gemBusy = true);
    final started = await _purchase.buyConsumable(product);
    if (!started && mounted) {
      setState(() => _gemBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _purchase.lastGemQueryMessage ?? 'Satın alma başlatılamadı.',
          ),
        ),
      );
    }
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    final itemId = (item['id'] as num?)?.toInt() ?? 0;
    if (itemId <= 0 || _buying) return;

    final coins = (_stats['coins'] as num?)?.toInt() ?? 0;
    final cost = (item['coin_cost'] as num?)?.toInt() ?? 0;
    if (coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeterli coin yok!'),
          backgroundColor: practiceRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _buying = true);
    final result = await _api.buyShopItem(itemId);
    setState(() => _buying = false);

    if (!mounted) return;
    if (result != null) {
      await PracticeSoundService.playComplete();
      await _load();
      _showSuccessSheet(item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satin alma başarısiz. Tekrar dene.'),
          backgroundColor: practiceRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _redeemPromo() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: practicePaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Promosyon kodu',
            style: TextStyle(color: practiceInk, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          decoration: const InputDecoration(hintText: 'Kodu gir'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('KULLAN'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final result = await _api.redeemPromoCode(code);
    if (!mounted) return;
    final ok = result != null &&
        result['success'] != false &&
        (result['success'] == true ||
            result['reward'] != null ||
            result['coins'] != null ||
            result['reward_coins'] != null);
    if (ok) {
      await PracticeSoundService.onBadgeEarned();
      await _load();
      if (!mounted) return;
      final msg = '${result['message'] ?? 'Kod kullanıldı! Ödülün eklendi.'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: practiceBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final msg = '${result?['message'] ?? 'Geçersiz veya kullanılmış kod.'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: practiceRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PracticeConfettiOverlay(
              active: true,
              child:
                  PracticeMascot(size: 120, mood: PracticeMascotMood.excited),
            ),
            const SizedBox(height: 16),
            Text(
              '${item['name'] ?? 'Item'} alındı!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item['description'] ?? 'Envantere eklendi.'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w700,
                  height: 1.35),
            ),
            const SizedBox(height: 20),
            PracticePrimaryButton(
              label: 'HARIKA!',
              color: practiceBlue,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = (_stats['coins'] as num?)?.toInt() ?? 0;
    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        backgroundColor: practiceKraft,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title:
            const Text('Mağaza', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded,
                    color: practiceBlue, size: 22),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: practiceBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Mağaza yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [practiceBlue, practiceBlueDark],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mücevherlerinle AI hakkı, can ve güçlendirme al!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const PracticeTreasure(size: 80),
                      ],
                    ),
                  ),
                  _GemPacksSection(
                    products: _gemProducts,
                    message: _gemQueryMessage,
                    busy: _gemBusy,
                    onBuy: _buyGem,
                    onCheck: _load,
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) => _ShopItemCard(
                      item: _items[i],
                      coins: coins,
                      busy: _buying,
                      onBuy: () => _buy(_items[i]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PromoCodeCard(onRedeem: _redeemPromo),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((e) {
      final item = Map<String, dynamic>.from(e);
      item['name'] ??= item['title'];
      item['coin_cost'] ??= item['price_coins'];
      return item;
    }).toList();
  }

  // Sahte ürün gösterme — mağaza API'den (seed'li ürünler) gelir, yoksa boş.
  List<Map<String, dynamic>> _fallbackItems() => const [];
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.coins,
    required this.busy,
    required this.onBuy,
  });
  final Map<String, dynamic> item;
  final int coins;
  final bool busy;
  final VoidCallback onBuy;

  static final _icons = <String, IconData>{
    'heart': Icons.favorite_rounded,
    'freeze': Icons.ac_unit_rounded,
    'boost': Icons.bolt_rounded,
    'hint': Icons.lightbulb_rounded,
    'coin': Icons.diamond_rounded,
    'gem': Icons.diamond_rounded,
    // Double or Nothing (bahis) ve Hafta Sonu Amuleti gibi eşyalar:
    'casino': Icons.casino_rounded,
    'double': Icons.casino_rounded, // double_or_nothing
    'wager': Icons.casino_rounded,
    'spin': Icons.casino_rounded,
    'amulet': Icons.shield_rounded,
    'weekend': Icons.shield_rounded, // weekend_amulet
    'streak': Icons.local_fire_department_rounded,
    'chest': Icons.card_giftcard_rounded,
    'energy': Icons.battery_charging_full_rounded,
    'ai': Icons.auto_awesome_rounded,
    'coach': Icons.psychology_alt_rounded,
    'explain': Icons.psychology_alt_rounded,
    'roleplay': Icons.theater_comedy_rounded,
    'ticket': Icons.confirmation_number_rounded,
  };

  static final _colors = <String, Color>{
    'heart': practiceRed,
    'freeze': practiceBlue,
    'boost': practiceOrange,
    'hint': practiceYellow,
    'coin': practiceBlue,
    'gem': practiceBlue,
    'casino': practiceOrange,
    'double': practiceOrange,
    'wager': practiceOrange,
    'spin': practiceYellow,
    'amulet': practiceBlue,
    'weekend': practiceBlue,
    'streak': practiceOrange,
    'chest': practiceYellow,
    'energy': practiceGreen,
    'ai': practicePurple,
    'coach': practicePurple,
    'explain': practicePurple,
    'roleplay': practicePurple,
    'ticket': practiceBlue,
  };

  @override
  Widget build(BuildContext context) {
    final cost = (item['coin_cost'] as num?)?.toInt() ?? 0;
    final canAfford = coins >= cost;
    final key = '${item['key'] ?? item['icon'] ?? ''}';
    final icon =
        _icons[key] ?? _icons[key.split('_').first] ?? Icons.star_rounded;
    final color = _colors[key] ?? _colors[key.split('_').first] ?? practiceBlue;
    return Container(
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 38),
          ),
          const SizedBox(height: 10),
          Text(
            '${item['name'] ?? 'Item'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: practiceInk,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item['description'] ?? ''}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: practiceMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: canAfford && !busy ? onBuy : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: canAfford ? practiceBlue : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Promosyon Kodu" kartı — dokununca kod giriş diyaloğunu açar.
class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({required this.onRedeem});

  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRedeem,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: practicePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: practiceLine, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: practiceRed.withValues(alpha: .12),
                shape: BoxShape.circle,
                border: Border.all(color: practiceRed, width: 2),
              ),
              child: const Icon(Icons.confirmation_number_rounded,
                  color: practiceRed, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promosyon kodu',
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ödül kazanmak için bir promosyon kodu gir.',
                    style: TextStyle(
                      color: practiceMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: practiceBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: practiceDarken(practiceBlue, .12), width: 2),
              ),
              child: const Text(
                'KULLAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gerçek-paralı mücevher paketleri. Store'da ürün tanımlı değilse (ya da
/// yayınlanmamış uygulamada) liste boş gelir → "yakında" notu gösterilir.
class _GemPacksSection extends StatelessWidget {
  const _GemPacksSection({
    required this.products,
    required this.message,
    required this.busy,
    required this.onBuy,
    required this.onCheck,
  });

  final List<ProductDetails> products;
  final String? message;
  final bool busy;
  final ValueChanged<ProductDetails> onBuy;
  final Future<void> Function() onCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            'Mücevher paketleri',
            style: TextStyle(
              color: practiceInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: practicePaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: practiceLine, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: practiceMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message ??
                            'Mücevher paketleri, mağaza ürünleri (Google Play / App Store) tanımlanınca burada görünür.',
                        style: const TextStyle(
                          color: practiceMuted,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: busy ? null : () => onCheck(),
                  child: const Text('STORE BAĞLANTISINI KONTROL ET'),
                ),
              ],
            ),
          )
        else
          for (final p in products)
            _GemPackCard(product: p, busy: busy, onBuy: () => onBuy(p)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GemPackCard extends StatelessWidget {
  const _GemPackCard({
    required this.product,
    required this.busy,
    required this.onBuy,
  });

  final ProductDetails product;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    // Ürün başlığı çoğu zaman "(Uygulama Adı)" eki taşır — temizle.
    final title = product.title.split('(').first.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: practiceBlue.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: practiceBlue, width: 2),
            ),
            child: const Icon(Icons.diamond_rounded,
                color: practiceBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.isEmpty ? 'Mücevher paketi' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: busy ? null : onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: busy ? practiceMuted : practiceBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: practiceDarken(practiceBlue, .12), width: 2),
              ),
              child: Text(
                product.price,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
