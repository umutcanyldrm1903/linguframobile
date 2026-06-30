import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.title,
    this.successContains,
    this.failContains,
  });

  final String url;
  final String? title;
  final String? successContains;
  final String? failContains;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onNavigationRequest: (request) {
            if (_handleRedirect(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url ?? '';
            if (url.isEmpty) return;
            _handleRedirect(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _handleRedirect(String url) {
    final successKey = widget.successContains ?? 'webview-success-payment';
    final failKey = widget.failContains ?? 'webview-failed-payment';
    if (url.contains(successKey)) {
      Navigator.pop(context, true);
      return true;
    }
    if (url.contains(failKey)) {
      Navigator.pop(context, false);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _progress >= 100;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          widget.title ?? AppStrings.t('Payment'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.ink,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // İnce üst kart: güvenli ödeme rozeti.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.sm,
                ),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  radius: AppRadius.md,
                  child: Row(
                    children: [
                      const AppStatPill(
                        icon: Icons.lock_rounded,
                        label: 'Güvenli ödeme',
                        color: AppPalette.success,
                        onLight: true,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.verified_user_rounded,
                        size: 18,
                        color: AppPalette.success.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
              ),
              // İnce gradyan ilerleme çubuğu (gerçek yükleme yüzdesi).
              _GradientProgressBar(progress: _progress),
              // WebView — yüklenince yumuşak fade-in.
              Expanded(
                child: AnimatedOpacity(
                  opacity: loaded ? 1 : 0,
                  duration: AppMotion.normal,
                  curve: Curves.easeOut,
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İnce gradyanlı ilerleme çubuğu — gerçek WebView yükleme yüzdesini gösterir.
class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final complete = progress >= 100;
    return SizedBox(
      height: 3,
      child: AnimatedOpacity(
        opacity: complete ? 0 : 1,
        duration: AppMotion.fast,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * (progress.clamp(0, 100) / 100);
            return Stack(
              children: [
                Container(color: AppPalette.line.withValues(alpha: 0.6)),
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: Curves.easeOut,
                  width: width,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: AppRadius.pill,
                    boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.30),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
