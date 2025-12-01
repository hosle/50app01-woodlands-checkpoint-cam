import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/app_secrets.dart';
import '../viewmodels/woodlands_checkpoints_view_model.dart';

class WoodlandsCheckpointsPage extends StatefulWidget {
  const WoodlandsCheckpointsPage({super.key});

  @override
  State<WoodlandsCheckpointsPage> createState() =>
      _WoodlandsCheckpointsPageState();
}

class _WoodlandsCheckpointsPageState extends State<WoodlandsCheckpointsPage> {
  late final WoodlandsCheckpointsViewModel _viewModel;
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasNetworkAccess = false;
  bool _hasCheckedNetworkAccess = false;
  ConnectivityResult? _lastConnectivityResult;
  bool _isPageView = true;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _refreshTimer;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Banner ad unit ID is loaded from secrets.json
  String get _bannerAdUnitId => AppSecrets.instance.getBannerAdUnitId();

  @override
  void initState() {
    super.initState();
    _viewModel = WoodlandsCheckpointsViewModel();
    _connectivity = Connectivity();
    _initializeNetworkAccessMonitoring();
    _pageController = PageController();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && _hasNetworkAccess) {
        _viewModel.loadImages();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    _pageController.dispose();
    _viewModel.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd(int width) async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    debugPrint('Loading banner ad with width: $width');
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      debugPrint('Failed to get ad size');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Ad was loaded.");
          // if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          // }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Ad failed to load with error: $error");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
            });
          }
        },
        onAdOpened: (Ad ad) {
          // Called when an ad opens an overlay that covers the screen.
          debugPrint("Ad was opened.");
        },
        onAdClosed: (Ad ad) {
          // Called when an ad removes an overlay that covers the screen.
          debugPrint("Ad was closed.");
        },
        onAdImpression: (Ad ad) {
          // Called when an impression occurs on the ad.
          debugPrint("Ad recorded an impression.");
        },
        onAdClicked: (Ad ad) {
          // Called when an a click event occurs on the ad.
          debugPrint("Ad was clicked.");
        },
        onAdWillDismissScreen: (Ad ad) {
          // iOS only. Called before dismissing a full screen view.
          debugPrint("Ad will be dismissed.");
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (!_hasCheckedNetworkAccess) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (!_hasNetworkAccess) {
      bodyContent = _NetworkPermissionPrompt(onRetry: _checkNetworkAccess);
    } else {
      bodyContent = AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null) {
            return _ErrorState(
              errorMessage: _viewModel.errorMessage!,
              onRetry: _viewModel.loadImages,
            );
          }

          final checkpoints = _viewModel.images;

          if (checkpoints.isEmpty) {
            return const _EmptyState();
          }

          if (_isPageView) {
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: checkpoints.length,
                    itemBuilder: (context, index) {
                      final checkpoint = checkpoints[index];
                      return _CheckpointCard(
                        title: checkpoint.title,
                        imageUrl: checkpoint.imageUrl,
                        capturedAt: checkpoint.capturedAt,
                        isPageView: true,
                      );
                    },
                  ),
                ),
                _PageIndicator(
                  currentPage: _currentPage,
                  pageCount: checkpoints.length,
                ),
              ],
            );
          } else {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: checkpoints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final checkpoint = checkpoints[index];
                return _CheckpointCard(
                  title: checkpoint.title,
                  imageUrl: checkpoint.imageUrl,
                  capturedAt: checkpoint.capturedAt,
                  isPageView: false,
                );
              },
            );
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Woodlands Checkpoint'),
        actions: [
          // Test Crash button - visible in debug and profile builds, hidden in release
          if (!kReleaseMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              onPressed: () => _showCrashTestDialog(context),
              tooltip: 'Test Crashlytics',
            ),
          IconButton(
            icon: Icon(_isPageView ? Icons.view_list : Icons.view_carousel),
            onPressed: () {
              setState(() {
                _isPageView = !_isPageView;
              });
            },
            tooltip: _isPageView
                ? 'Switch to List View'
                : 'Switch to Page View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad at the top with LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.toInt();
              debugPrint('LayoutBuilder width: $width');

              // Load ad if not loaded and width is available
              if (_bannerAd == null && width > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadBannerAd(width);
                });
              }

              return _isBannerAdLoaded && _bannerAd != null
                  ? SafeArea(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // Main content
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Future<void> _initializeNetworkAccessMonitoring() async {
    final initialResult = await _connectivity.checkConnectivity();
    await _handleConnectivityResult(initialResult);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityResult,
    );
  }

  Future<void> _checkNetworkAccess() async {
    final result = await _connectivity.checkConnectivity();
    await _handleConnectivityResult(result, forceLoad: true);
  }

  void _showCrashTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Crashlytics'),
        content: const Text(
          'Choose a crash type to test.\n\n'
          '⚠️ Important: Disconnect from debugger first!\n'
          '1. Stop the app in Xcode/VS Code\n'
          '2. Open the app from home screen\n'
          '3. Then trigger the crash\n'
          '4. Reopen app to send crash report',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Log a non-fatal error
              FirebaseCrashlytics.instance.recordError(
                Exception('Test non-fatal error'),
                StackTrace.current,
                reason: 'Testing Crashlytics non-fatal error',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Non-fatal error logged!')),
              );
            },
            child: const Text('Non-Fatal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // Use native crash - works on both iOS and Android
              FirebaseCrashlytics.instance.crash();
            },
            child: const Text(
              'Fatal Crash',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnectivityResult(
    List<ConnectivityResult> result, {
    bool forceLoad = false,
  }) async {
    final previousResult = _lastConnectivityResult;
    final hasAccess = result.isNotEmpty && result[0] != ConnectivityResult.none;

    if (!mounted) {
      return;
    }

    setState(() {
      _hasNetworkAccess = hasAccess;
      _hasCheckedNetworkAccess = true;
      _lastConnectivityResult = result.isNotEmpty ? result[0] : null;
    });

    final regainedAccess =
        hasAccess &&
        (previousResult == null || previousResult == ConnectivityResult.none);

    if ((forceLoad && hasAccess) || regainedAccess) {
      await _viewModel.loadImages();
    }
  }
}

class _CheckpointCard extends StatefulWidget {
  const _CheckpointCard({
    required this.title,
    required this.imageUrl,
    this.capturedAt,
    this.isPageView = true,
  });

  final String title;
  final String imageUrl;
  final DateTime? capturedAt;
  final bool isPageView;

  @override
  State<_CheckpointCard> createState() => _CheckpointCardState();
}

class _CheckpointCardState extends State<_CheckpointCard> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  // Native ad unit ID is loaded from secrets.json
  String get _adUnitId => AppSecrets.instance.getNativeAdUnitId();

  @override
  void initState() {
    super.initState();
    // _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAdIsLoaded = false;
            });
          }
        },
      ),
      request: const AdRequest(),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    Widget cardContent = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.isPageView
              ? Expanded(child: _buildImage(context))
              : AspectRatio(aspectRatio: 3 / 2, child: _buildImage(context)),

          // Native Ad
          if (_nativeAdIsLoaded && _nativeAd != null)
            Container(
              constraints: BoxConstraints(minHeight: 200, maxHeight: 200),
              child: AdWidget(ad: _nativeAd!),
            ),

          // else
          //   SizedBox(height: 200, width: double.infinity),
          if (widget.capturedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Captured: ${_formatCaptureTime(widget.capturedAt!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ).copyWith(bottom: 20),
            child: Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isPageView) {
      return Center(
        child: SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.7,
          child: cardContent,
        ),
      );
    } else {
      return cardContent;
    }
  }

  Widget _buildImage(BuildContext context) {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, size: 48),
              const SizedBox(height: 8),
              Text(
                'Image failed to load',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCaptureTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date =
        '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
    final time =
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}:${_twoDigits(local.second)}';
    return '$date $time';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            'No checkpoint images available.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (index) => _IndicatorDot(isActive: index == currentPage),
        ),
      ),
    );
  }
}

class _NetworkPermissionPrompt extends StatelessWidget {
  const _NetworkPermissionPrompt({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Network access is currently disabled. Please enable Wi-Fi or mobile data for this app to continue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
