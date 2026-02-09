import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

import '../models/app_config.dart';
import '../models/app_secrets.dart';

class MySecondLinkPage extends StatefulWidget {
  const MySecondLinkPage({
    super.key,
    required this.isPageView,
    required this.onToggleViewMode,
  });

  final bool isPageView;
  final VoidCallback onToggleViewMode;

  @override
  State<MySecondLinkPage> createState() => _MySecondLinkPageState();
}

class _MySecondLinkPageState extends State<MySecondLinkPage> {
  bool _isLiveEnv = false;

  static const String _liveBaseUrl =
      'https://woodlands-checkpoint-sg-249264132946.asia-southeast1.run.app';
// https://default-249264132946.asia-southeast1.run.app
  static const String _localBaseUrl = 'http://192.168.1.56:8080';

  String _baseUrl = kReleaseMode ? _liveBaseUrl : _localBaseUrl;

  // static const String _baseUrl = ;

  late PageController _pageController;
  int _currentPage = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // API state
  bool _isLoading = false;
  String? _errorMessage;
  List<CameraImage> _images = [];
  DateTime? _captureTime;

  // Banner ad unit ID is loaded from secrets.json
  String get _bannerAdUnitId => AppSecrets.instance.getBannerAdUnitId();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _toggleLiveEnv() {
    // Add this
    setState(() {
      _isLiveEnv = !_isLiveEnv;
      _baseUrl = _isLiveEnv ? _liveBaseUrl : _localBaseUrl;

      _isLoading ? null : _fetchImages();
    });
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
    });

    // Reset page controller to first page
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/my_second_link'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<CameraImage> images = [];
        DateTime? captureTime;

        // Parse the JSON response - assuming it's a list of objects with 'src' or 'image' field
        if (jsonData is List) {
          for (final item in jsonData) {
            final src = '$_baseUrl/${item['src']}';
            final title =
                item['title'] ?? item['name'] ?? 'Camera ${images.length + 1}';
            if (src != null) {
              images.add(
                CameraImage(title: title.toString(), imageUrl: src.toString()),
              );
            }
          }
        } else if (jsonData is Map) {
          // Parse capture_time if available (Unix timestamp in seconds)
          final captureTimeValue = jsonData['capture_time'];
          if (captureTimeValue != null && captureTimeValue is int) {
            captureTime = DateTime.fromMillisecondsSinceEpoch(
              captureTimeValue * 1000,
            );
          }

          // If it's an object with an array field
          final dataList = jsonData['data'];

          if (dataList is List) {
            for (final item in dataList) {
              final src = '$_baseUrl/${item['src']}';

              final title = item['title'];
              if (src != null) {
                images.add(
                  CameraImage(
                    title: title.toString(),
                    imageUrl: src.toString(),
                  ),
                );
              }
            }
          }
        }

        setState(() {
          _images = images;
          _captureTime = captureTime;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load images. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching images: $e');
      setState(() {
        _errorMessage = 'Unable to load images: $e';
        _isLoading = false;
      });
    }
  }

  void _loadBannerAd(int width) async {
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
          setState(() {
            _isBannerAdLoaded = true;
          });
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
          debugPrint("Ad was opened.");
        },
        onAdClosed: (Ad ad) {
          debugPrint("Ad was closed.");
        },
        onAdImpression: (Ad ad) {
          debugPrint("Ad recorded an impression.");
        },
        onAdClicked: (Ad ad) {
          debugPrint("Ad was clicked.");
        },
        onAdWillDismissScreen: (Ad ad) {
          debugPrint("Ad will be dismissed.");
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malaysia 2nd Link'),
        actions: [
          if (!kReleaseMode && !AppConfig.noDebugEntry)
            IconButton(
              icon: Icon(_isLiveEnv ? Icons.public : Icons.public_off),
              onPressed: _toggleLiveEnv,
              tooltip: _isLiveEnv
                  ? 'Switch to Live Env'
                  : 'Switch to Local Env',
            ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchImages,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              widget.isPageView ? Icons.view_list : Icons.view_carousel,
            ),
            onPressed: widget.onToggleViewMode,
            tooltip: widget.isPageView
                ? 'Switch to List View'
                : 'Switch to Page View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad (hidden when NO_ADS build flag is set)
          if (!AppConfig.noAds)
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchImages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 48),
            SizedBox(height: 12),
            Text('No images available.'),
          ],
        ),
      );
    }

    return widget.isPageView ? _buildPageView() : _buildListView();
  }

  Widget _buildPageView() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return _ImageCard(
                title: image.title,
                imageUrl: image.imageUrl,
                capturedAt: _captureTime,
                isPageView: true,
              );
            },
          ),
        ),
        _PageIndicator(currentPage: _currentPage, pageCount: _images.length),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _images.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final image = _images[index];
        return _ImageCard(
          title: image.title,
          imageUrl: image.imageUrl,
          capturedAt: _captureTime,
          isPageView: false,
        );
      },
    );
  }
}

class CameraImage {
  final String title;
  final String imageUrl;

  CameraImage({required this.title, required this.imageUrl});
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
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
          isPageView
              ? Expanded(child: _buildImage(context))
              : AspectRatio(aspectRatio: 3 / 2, child: _buildImage(context)),
          if (capturedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Captured: ${_formatCaptureTime(capturedAt!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ).copyWith(bottom: 20, top: capturedAt == null ? 12 : 0),
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (isPageView) {
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
      imageUrl,
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
