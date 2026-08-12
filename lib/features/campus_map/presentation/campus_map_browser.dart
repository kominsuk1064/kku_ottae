import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef CampusMapBrowserFactory =
    CampusMapBrowser Function(CampusMapBrowserCallbacks callbacks);

final class CampusMapBrowserCallbacks {
  const CampusMapBrowserCallbacks({
    required this.onPageStarted,
    required this.onPageFinished,
    required this.onProgress,
    required this.onWebResourceError,
  });

  final VoidCallback onPageStarted;
  final VoidCallback onPageFinished;
  final ValueChanged<int> onProgress;
  final ValueChanged<CampusMapBrowserError> onWebResourceError;
}

final class CampusMapBrowserError {
  const CampusMapBrowserError({
    required this.description,
    required this.isForMainFrame,
  });

  final String description;
  final bool? isForMainFrame;
}

abstract interface class CampusMapBrowser {
  Widget buildView();

  Future<void> load(Uri uri);

  Future<void> reload();
}

CampusMapBrowser createCampusMapBrowser(CampusMapBrowserCallbacks callbacks) {
  return WebViewCampusMapBrowser(callbacks);
}

final class WebViewCampusMapBrowser implements CampusMapBrowser {
  WebViewCampusMapBrowser(CampusMapBrowserCallbacks callbacks) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _mainFrameUri = Uri.tryParse(url);
            callbacks.onPageStarted();
          },
          onPageFinished: (_) => callbacks.onPageFinished(),
          onProgress: callbacks.onProgress,
          onHttpError: (error) {
            final requestUri = error.request?.uri;
            callbacks.onWebResourceError(
              CampusMapBrowserError(
                description: 'HTTP ${error.response?.statusCode ?? '오류'}',
                isForMainFrame:
                    requestUri == null || requestUri == _mainFrameUri,
              ),
            );
          },
          onWebResourceError: (error) {
            callbacks.onWebResourceError(
              CampusMapBrowserError(
                description: error.description,
                isForMainFrame: error.isForMainFrame,
              ),
            );
          },
        ),
      );
  }

  late final WebViewController _controller;
  Uri? _mainFrameUri;

  @override
  Widget buildView() {
    return WebViewWidget(
      key: const ValueKey('campus-map-webview'),
      controller: _controller,
    );
  }

  @override
  Future<void> load(Uri uri) {
    _mainFrameUri = uri;
    return _controller.loadRequest(uri);
  }

  @override
  Future<void> reload() => _controller.reload();
}
