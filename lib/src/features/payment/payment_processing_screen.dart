import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import 'payment_native_service.dart';
import '../student/checkout/student_payment_repository.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({
    super.key,
    required this.invoiceId,
    required this.paymentUrl,
  });

  final String invoiceId;
  final String paymentUrl;

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<String>? _deepLinkSub;
  PaymentStatus? _status;
  bool _checking = false;
  bool _opening = false;
  WebViewController? _webviewController;
  int _webProgress = 0;
  String? _lastDeepLink;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_shouldUseWebView()) {
      _initWebView();
    } else {
      _openPayment();
    }
    _startPolling();
    _listenDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkStatus(showToast: false);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkStatus(showToast: false);
    });
  }

  void _listenDeepLinks() {
    if (kIsWeb) return;
    _deepLinkSub = PaymentNativeService.deepLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return;
    if (_lastDeepLink == trimmed) return;
    _lastDeepLink = trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;
    if (uri.scheme != 'lingufranca') return;
    if (uri.host != 'payment') return;

    // Validate invoice_id parameter - must match current invoice
    final invoice = (uri.queryParameters['invoice_id'] ?? '').trim();
    if (invoice.isEmpty || invoice != widget.invoiceId) {
      // Prevent injection attacks - dön't process mismatched invoice IDs
      return;
    }

    // Only process 'failed' result - other results are handled by page redirects
    final result = (uri.queryParameters['result'] ?? '').toLowerCase();
    if (result == 'failed' && mounted) {
      Navigator.pop(context, false);
      return;
    }

    // For any other deep link from payment domain, check status
    _checkStatus(showToast: false);
  }

  bool _shouldUseWebView() {
    // In-app payment: keep the whole flow inside the app using an embedded WebView.
    // Limit to mobile platforms where webview_flutter is supported.
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  void _initWebView() {
    final url = widget.paymentUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    _webviewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _webProgress = progress);
          },
          onNavigationRequest: (request) {
            if (_handleRedirect(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final next = change.url ?? '';
            if (next.isEmpty) return;
            _handleRedirect(next);
          },
        ),
      )
      ..loadRequest(uri);
  }

  bool _handleRedirect(String url) {
    // Deep link emitted by the backend success/fail page (app_order_notification).
    if (url.startsWith('lingufranca://payment')) {
      _handleDeepLink(url);
      return true;
    }

    if (url.contains('webview-success-payment')) {
      Navigator.pop(context, true);
      return true;
    }
    if (url.contains('webview-failed-payment')) {
      Navigator.pop(context, false);
      return true;
    }
    if (url.contains('payment-success')) {
      Navigator.pop(context, true);
      return true;
    }
    if (url.contains('payment-failed')) {
      Navigator.pop(context, false);
      return true;
    }
    return false;
  }

  Future<void> _openPayment() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final url = widget.paymentUrl.trim();
      if (url.isEmpty) return;

      final nativeOpened = await PaymentNativeService().startPayment(
        paymentUrl: url,
        invoiceId: widget.invoiceId,
      );
      if (nativeOpened) return;

      final uri = Uri.tryParse(url);
      if (uri == null) return;

      final opened = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.externalApplication : LaunchMode.inAppBrowserView,
      );
      if (!opened) {
        final fallbackOpened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!fallbackOpened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('Could not open payment URL'))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _checkStatus({required bool showToast}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final status =
          await StudentPaymentRepository().fetchOrderStatus(widget.invoiceId);
      if (!mounted) return;
      setState(() => _status = status);

      if (status?.isSuccess ?? false) {
        _timer?.cancel();
        // Visual-only: real success celebration (does not alter the flow).
        if (!_celebrated) {
          _celebrated = true;
          showCelebration(
            context,
            title: AppStrings.t('Ödeme başarılı!'),
            subtitle: AppStrings.t('Payment Success.'),
            icon: Icons.verified_rounded,
            color: AppPalette.success,
          );
        }
        if (mounted) Navigator.pop(context, true);
        return;
      }

      if (status?.isFailed ?? false) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context, false);
        return;
      }

      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Payment is pending.'))),
        );
      }
    } catch (_) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Something went wrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isSuccess = status?.isSuccess ?? false;
    final isFailed = status?.isFailed ?? false;
    final statusLabel = status == null
        ? AppStrings.t('Processing')
        : (status.isSuccess
            ? AppStrings.t('Payment Success.')
            : (status.isFailed
                ? AppStrings.t('Payment Fail')
                : AppStrings.t('Payment is pending.')));

    final webview = _webviewController;
    if (webview != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            if (_webProgress < 100)
              LinearProgressIndicator(
                value: _webProgress / 100,
                minHeight: 3,
                backgroundColor: AppPalette.line,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.brand),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: _StatusCard(
                statusLabel: statusLabel,
                isSuccess: isSuccess,
                isFailed: isFailed,
                checking: _checking,
                onCheck: _checking ? null : () => _checkStatus(showToast: true),
                compact: true,
              ),
            ),
            Expanded(child: WebViewWidget(controller: webview)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: AppGlowBackground(
        accent: AppPalette.success,
        child: SafeArea(
          child: AnimatedPageEntrance(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                StaggeredReveal(
                  children: [
                    GradientHero(
                      gradient: AppGradients.hero,
                      glowColor: AppPalette.success,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppStatPill(
                                icon: Icons.lock_rounded,
                                label: AppStrings.t('Güvenli ödeme'),
                                color: AppPalette.success,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              AppStatPill(
                                icon: Icons.verified_user_rounded,
                                label: AppStrings.t('256-bit SSL'),
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            AppStrings.t('Make Payment'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t(
                              'Complete the payment in the opened page, then return to the app. We will automatically check the status.',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _StatusCard(
                      statusLabel: statusLabel,
                      isSuccess: isSuccess,
                      isFailed: isFailed,
                      checking: _checking,
                      onCheck:
                          _checking ? null : () => _checkStatus(showToast: true),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppGhostButton(
                            label: AppStrings.t('Open Payment Page'),
                            icon: Icons.open_in_new_rounded,
                            onPressed: _opening ? null : _openPayment,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: AppButton(
                            label: _checking
                                ? AppStrings.t('Submitting')
                                : AppStrings.t('Check Payment Status'),
                            tone: AppButtonTone.success,
                            icon: Icons.refresh_rounded,
                            loading: _checking,
                            onPressed: _checking
                                ? null
                                : () => _checkStatus(showToast: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 15, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Text(
                          '${AppStrings.t('Invoice')}: ${widget.invoiceId}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
      title: Text(
        AppStrings.t('Payment'),
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context, null),
      ),
    );
  }
}

/// Ödeme durumu kartı: işleniyorsa AppLoader/spinner, başarıda animasyonlu
/// onay tiki, başarısızlıkta AppErrorState. Sadece görsel katman.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.statusLabel,
    required this.isSuccess,
    required this.isFailed,
    required this.checking,
    required this.onCheck,
    this.compact = false,
  });

  final String statusLabel;
  final bool isSuccess;
  final bool isFailed;
  final bool checking;
  final VoidCallback? onCheck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isFailed) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: AppErrorState(
          message: statusLabel,
          onRetry: onCheck,
          retryLabel: AppStrings.t('Check Payment Status'),
        ),
      );
    }

    final accent = isSuccess ? AppPalette.success : AppColors.brand;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          _StatusGlyph(isSuccess: isSuccess, color: accent),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                if (!isSuccess) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.t('Payment is pending.'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (compact && !isSuccess)
            TextButton(
              onPressed: onCheck,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                AppStrings.t('Check Payment Status'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

/// Durum simgesi: işleniyorsa dönen spinner, başarıda animasyonlu onay tiki.
class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.isSuccess, required this.color});

  final bool isSuccess;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, v, _) => Transform.scale(
          scale: v.clamp(0.0, 1.2),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.success,
              boxShadow: AppShadows.glow(color, opacity: 0.34),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 26),
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}
