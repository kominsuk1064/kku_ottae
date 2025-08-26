import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CampusMapWebScreen extends StatefulWidget {
  const CampusMapWebScreen({super.key});
  @override
  State<CampusMapWebScreen> createState() => _CampusMapWebScreenState();
}

class _CampusMapWebScreenState extends State<CampusMapWebScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (e) => debugPrint('Web error: ${e.description}'),
        ),
      )
      ..loadRequest(Uri.parse('https://www.kku.ac.kr/campusMap.do'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학교 지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
