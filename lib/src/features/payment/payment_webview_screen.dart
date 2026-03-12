import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 3,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
