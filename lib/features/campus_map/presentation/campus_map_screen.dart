import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/campus_map_controller.dart';
import '../application/campus_map_state.dart';
import 'campus_map_browser.dart';

final _campusMapUri = Uri.https('www.kku.ac.kr', '/campusMap.do');

class CampusMapScreen extends ConsumerStatefulWidget {
  const CampusMapScreen({
    super.key,
    this.browserFactory = createCampusMapBrowser,
  });

  final CampusMapBrowserFactory browserFactory;

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  late final CampusMapBrowser _browser;

  @override
  void initState() {
    super.initState();
    _browser = widget.browserFactory(
      CampusMapBrowserCallbacks(
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        onProgress: _onProgress,
        onWebResourceError: _onWebResourceError,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref
            .read(campusMapControllerProvider.notifier)
            .loadInitial(() => _browser.load(_campusMapUri)),
      );
    });
  }

  void _onPageStarted() {
    if (mounted) {
      ref.read(campusMapControllerProvider.notifier).pageStarted();
    }
  }

  void _onPageFinished() {
    if (mounted) {
      ref.read(campusMapControllerProvider.notifier).pageFinished();
    }
  }

  void _onProgress(int progress) {
    if (mounted) {
      ref.read(campusMapControllerProvider.notifier).progressChanged(progress);
    }
  }

  void _onWebResourceError(CampusMapBrowserError error) {
    if (mounted) {
      ref
          .read(campusMapControllerProvider.notifier)
          .webResourceFailed(
            description: error.description,
            isForMainFrame: error.isForMainFrame,
          );
    }
  }

  void _reload() {
    unawaited(
      ref.read(campusMapControllerProvider.notifier).reload(_browser.reload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campusMapControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('학교 지도'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: CampusMapView(
          state: state,
          browserView: _browser.buildView(),
          onRetry: _reload,
        ),
      ),
    );
  }
}

class CampusMapView extends StatelessWidget {
  const CampusMapView({
    required this.state,
    required this.browserView,
    required this.onRetry,
    super.key,
  });

  final CampusMapState state;
  final Widget browserView;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        browserView,
        if (state.status == CampusMapStatus.loading)
          _LoadingView(progress: state.progress),
        if (state.status == CampusMapStatus.error)
          _ErrorView(
            message:
                state.errorMessage ?? CampusMapController.loadFailureMessage,
            onRetry: onRetry,
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress == 0 ? null : progress / 100;

    return ColoredBox(
      key: const ValueKey('campus-map-loading'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: '학교 지도 불러오는 중',
          value: progress == 0 ? null : '$progress%',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(value: progressValue),
              const SizedBox(height: 16),
              const Text('학교 지도를 불러오는 중입니다.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('campus-map-error'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
