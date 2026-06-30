import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import '../student/checkout/student_payment_repository.dart';
import 'payment_native_service.dart';

class IyzicoNativePaymentScreen extends StatefulWidget {
  const IyzicoNativePaymentScreen({
    super.key,
    required this.planKey,
    required this.planTitle,
    required this.currency,
    required this.priceLabel,
  });

  final String planKey;
  final String planTitle;
  final String currency;
  final String priceLabel;

  @override
  State<IyzicoNativePaymentScreen> createState() =>
      _IyzicoNativePaymentScreenState();
}

class _IyzicoNativePaymentScreenState extends State<IyzicoNativePaymentScreen> {
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvcController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D+'), '');

  String? _validate() {
    final holder = _cardHolderController.text.trim();
    if (holder.isEmpty) return AppStrings.t('Card holder name is required');

    final number = _digitsOnly(_cardNumberController.text);
    if (number.length < 13 || number.length > 19) {
      return AppStrings.t('Card number is invalid');
    }

    final month = int.tryParse(_digitsOnly(_monthController.text)) ?? 0;
    if (month < 1 || month > 12) return AppStrings.t('Expiry month is invalid');

    var yearRaw = _digitsOnly(_yearController.text);
    if (yearRaw.length == 2) yearRaw = '20$yearRaw';
    final year = int.tryParse(yearRaw) ?? 0;
    if (year < 2000 || year > 2100) return AppStrings.t('Expiry year is invalid');

    final cvc = _digitsOnly(_cvcController.text);
    if (cvc.length < 3 || cvc.length > 4) return AppStrings.t('CVC is invalid');

    return null;
  }

  Future<void> _pay() async {
    if (_submitting) return;
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    try {
      var expireYear = _digitsOnly(_yearController.text);
      if (expireYear.length == 2) expireYear = '20$expireYear';

      final init = await StudentPaymentRepository().initIyzico3dsPlanPayment(
        planKey: widget.planKey,
        currency: widget.currency,
        cardHolderName: _cardHolderController.text.trim(),
        cardNumber: _digitsOnly(_cardNumberController.text),
        expireMonth: _digitsOnly(_monthController.text).padLeft(2, '0'),
        expireYear: expireYear,
        cvc: _digitsOnly(_cvcController.text),
      );

      final invoiceId = init?.invoiceId ?? '';
      final html = init?.htmlContent ?? '';
      if (invoiceId.isEmpty || html.isEmpty) {
        throw Exception('missing_3ds_html');
      }

      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => Iyzico3dsScreen(
            invoiceId: invoiceId,
            htmlContent: html,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      final message = _extractError(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is Map) {
          return message.values.map((value) => value.toString()).join('\n');
        }
      }
      if (error.response?.statusCode == 401) {
        return AppStrings.t('Please login first');
      }
    }
    return AppStrings.t('Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Payment')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        accent: AppColors.brand,
        child: SafeArea(
          top: false,
          child: AnimatedPageEntrance(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                GradientHero(
                  gradient: AppGradients.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: AppRadius.all(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(
                              AppStrings.t('Pay With Card'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        widget.planTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.priceLabel} ${widget.currency}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: const [
                          AppStatPill(
                            icon: Icons.credit_card_rounded,
                            label: 'Visa',
                          ),
                          AppStatPill(
                            icon: Icons.credit_card_rounded,
                            label: 'Mastercard',
                          ),
                          AppStatPill(
                            icon: Icons.verified_user_rounded,
                            label: '3D Secure',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Card Holder Name'),
                        icon: Icons.badge_rounded,
                      ),
                      TextField(
                        controller: _cardHolderController,
                        decoration: _fieldDecoration(
                          AppStrings.t('Card Holder Name'),
                          Icons.person_rounded,
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.creditCardName],
                      ),
                      const SizedBox(height: AppSpace.md),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                        ],
                        decoration: _fieldDecoration(
                          AppStrings.t('Card Number'),
                          Icons.credit_card_rounded,
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.creditCardNumber],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _monthController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: _fieldDecoration(
                                AppStrings.t('MM'),
                                null,
                              ),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.creditCardExpirationMonth,
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: TextField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: _fieldDecoration(
                                AppStrings.t('YYYY'),
                                null,
                              ),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.creditCardExpirationYear,
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: TextField(
                              controller: _cvcController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: _fieldDecoration(
                                AppStrings.t('CVC'),
                                Icons.lock_rounded,
                              ),
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              autofillHints: const [
                                AutofillHints.creditCardSecurityCode,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 16,
                            color: AppPalette.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.t(
                                '3D Secure verification may open a confirmation screen inside the app.',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: _submitting
                      ? AppStrings.t('Submitting')
                      : AppStrings.t('Make Payment'),
                  onPressed: _submitting ? null : _pay,
                  loading: _submitting,
                  tone: AppButtonTone.success,
                  icon: Icons.lock_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: AppColors.muted),
      filled: true,
      fillColor: AppPalette.cloud,
      border: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
    );
  }
}

class Iyzico3dsScreen extends StatefulWidget {
  const Iyzico3dsScreen({
    super.key,
    required this.invoiceId,
    required this.htmlContent,
  });

  final String invoiceId;
  final String htmlContent;

  @override
  State<Iyzico3dsScreen> createState() => _Iyzico3dsScreenState();
}

class _Iyzico3dsScreenState extends State<Iyzico3dsScreen>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  Timer? _timer;
  StreamSubscription<String>? _deepLinkSub;
  PaymentStatus? _status;
  bool _checking = false;
  int _progress = 0;
  bool _celebrated = false;

  /// Gerçek başarı anında (tek seferlik) kutlama overlay'i + geri dönüş.
  void _completeSuccess() {
    if (_celebrated) return;
    _celebrated = true;
    _timer?.cancel();
    if (!mounted) return;
    showCelebration(
      context,
      title: AppStrings.t('Ödeme başarılı!'),
      subtitle: AppStrings.t('Payment Success.'),
      icon: Icons.verified_rounded,
      color: AppPalette.success,
    );
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
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

  void _listenDeepLinks() {
    if (kIsWeb) return;
    _deepLinkSub = PaymentNativeService.deepLinkStream.listen(_handleDeepLink);
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkStatus(showToast: false);
    });
  }

  void _initWebView() {
    final html = _decodeHtml(widget.htmlContent);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
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
      ..loadHtmlString(html);
  }

  String _decodeHtml(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('<html') || trimmed.startsWith('<')) {
      return trimmed;
    }

    try {
      return utf8.decode(base64.decode(trimmed));
    } catch (_) {
      return trimmed;
    }
  }

  bool _handleRedirect(String url) {
    if (url.startsWith('lingufranca://payment')) {
      _handleDeepLink(url);
      return true;
    }

    if (url.contains('payment-success')) {
      _completeSuccess();
      return true;
    }
    if (url.contains('payment-failed')) {
      Navigator.pop(context, false);
      return true;
    }
    return false;
  }

  void _handleDeepLink(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    if (uri.scheme != 'lingufranca') return;
    if (uri.host != 'payment') return;

    final invoice = (uri.queryParameters['invoice_id'] ?? '').trim();
    if (invoice.isEmpty || invoice != widget.invoiceId) return;

    final result = (uri.queryParameters['result'] ?? '').toLowerCase();
    if (result == 'failed' && mounted) {
      Navigator.pop(context, false);
      return;
    }

    _checkStatus(showToast: false);
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
        if (mounted) _completeSuccess();
        return;
      }

      if (status?.isFailed ?? false) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context, false);
        return;
      }

      if (showToast && mounted) {
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
    final theme = Theme.of(context);
    final web = _controller;
    final status = _status;
    final bool isSuccess = status?.isSuccess ?? false;
    final bool isFailed = status?.isFailed ?? false;
    final statusLabel = status == null
        ? AppStrings.t('Processing')
        : (isSuccess
            ? AppStrings.t('Payment Success.')
            : (isFailed
                ? AppStrings.t('Payment Fail')
                : AppStrings.t('Payment is pending.')));

    final Color accent = isSuccess
        ? AppPalette.success
        : (isFailed ? AppPalette.danger : AppColors.brand);
    final IconData statusIcon = isSuccess
        ? Icons.verified_rounded
        : (isFailed ? Icons.error_rounded : Icons.shield_rounded);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Payment')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 3,
              backgroundColor: AppPalette.line,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  if (isFailed)
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, size: 22, color: accent),
                    )
                  else
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const AppStatPill(
                          icon: Icons.lock_rounded,
                          label: '3D Secure',
                          color: AppPalette.success,
                          onLight: true,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _checking ? null : () => _checkStatus(showToast: true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                    ),
                    child: Text(
                      AppStrings.t('Check Payment Status'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: web == null
                ? const AppLoader()
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: WebViewWidget(controller: web),
                  ),
          ),
        ],
      ),
    );
  }
}
