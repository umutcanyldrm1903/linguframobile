import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_strings.dart';

class ContentWebViewScreen extends StatefulWidget {
  const ContentWebViewScreen({
    super.key,
    required this.loadUrl,
    required this.title,
    this.externalUrl,
    this.actionLabel,
  });

  final String loadUrl;
  final String title;
  final String? externalUrl;
  final String? actionLabel;

  @override
  State<ContentWebViewScreen> createState() => _ContentWebViewScreenState();
}

class _ContentWebViewScreenState extends State<ContentWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  Uri? get _externalUri => Uri.tryParse((widget.externalUrl ?? '').trim());

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loadUrl));
  }

  Future<void> _openExternally() async {
    final uri = _externalUri;
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened || !mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final externalUri = _externalUri;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (externalUri != null)
            TextButton.icon(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new),
              label: Text(widget.actionLabel ?? AppStrings.t('Open')),
            ),
        ],
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
