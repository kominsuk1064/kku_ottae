import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FacilitySchoolScreen extends StatefulWidget {
  const FacilitySchoolScreen({super.key});

  @override
  State<FacilitySchoolScreen> createState() => _FacilitySchoolScreenState();
}

class _FacilitySchoolScreenState extends State<FacilitySchoolScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset('assets/html/kakaoMap.html'); // ✅ 이거 유지
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller), // ✅ 전체 화면으로 WebView
    );
  }
}
