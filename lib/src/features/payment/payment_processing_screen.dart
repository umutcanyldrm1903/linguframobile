import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_strings.dart';
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
      // Prevent injection attacks - don't process mismatched invoice IDs
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
        appBar: AppBar(
          title: Text(AppStrings.t('Payment')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, null),
          ),
        ),
        body: Column(
          children: [
            if (_webProgress < 100)
              LinearProgressIndicator(
                value: _webProgress / 100,
                minHeight: 3,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2.5),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _checking ? null : () => _checkStatus(showToast: true),
                      child: Text(AppStrings.t('Check Payment Status')),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: WebViewWidget(controller: webview)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('Payment')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t('Make Payment'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.t(
              'Complete the payment in the opened page, then return to the app. We will automatically check the status.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 2.5),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _opening ? null : _openPayment,
                  child: Text(AppStrings.t('Open Payment Page')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checking ? null : () => _checkStatus(showToast: true),
                  child: Text(
                    _checking ? AppStrings.t('Submitting') : AppStrings.t('Check Payment Status'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${AppStrings.t('Invoice')}: ${widget.invoiceId}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
