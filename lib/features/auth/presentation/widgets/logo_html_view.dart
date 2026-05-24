import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LogoHtmlView extends StatefulWidget {
  final double height;
  final double borderRadius;
  const LogoHtmlView({super.key, this.height = 140, this.borderRadius = 20});

  @override
  State<LogoHtmlView> createState() => _LogoHtmlViewState();
}

class _LogoHtmlViewState extends State<LogoHtmlView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAsset('assets/images/logo.png');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}


