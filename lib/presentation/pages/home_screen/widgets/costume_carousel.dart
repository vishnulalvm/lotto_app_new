import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SimpleCarouselWidget extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onImageTap;
  final double? height;
  final double? viewportFraction;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  const SimpleCarouselWidget({
    super.key,
    required this.images,
    this.onImageTap,
    this.height,
    this.viewportFraction,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.gradientStartColor,
    this.gradientEndColor,
  });

  @override
  State<SimpleCarouselWidget> createState() => _SimpleCarouselWidgetState();
}

class _SimpleCarouselWidgetState extends State<SimpleCarouselWidget>
    with AutomaticKeepAliveClientMixin {
  // Preload controller for better performance
  final PageController _pageController = PageController();

  // Keep alive to prevent rebuilds when scrolling
  @override
  bool get wantKeepAlive => true;


  @override
  void didUpdateWidget(SimpleCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if images have changed
    if (!_listEquals(oldWidget.images, widget.images)) {
      setState(() {
        // Trigger rebuild when images change
      });
    }
  }

  // Helper method to compare lists
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _displayImages {
    return widget.images;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super for AutomaticKeepAliveClientMixin

    return Padding(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 8),
      child: CarouselSlider(
        options: CarouselOptions(
          height: widget.height ??
              AppResponsive.height(
                  context, AppResponsive.isMobile(context) ? 15 : 20),
          autoPlay: widget.autoPlay,
          autoPlayInterval: widget.autoPlayInterval,
          enlargeCenterPage: true,
          viewportFraction: widget.viewportFraction ??
              (AppResponsive.isMobile(context) ? 0.85 : 0.7),
          // Add performance optimizations
          enableInfiniteScroll: _displayImages.length > 1,
          pauseAutoPlayOnTouch: true,
          pauseAutoPlayOnManualNavigate: true,
        ),
        items: _displayImages.map((imageUrl) {
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: widget.onImageTap,
                child: Container(
                  width: AppResponsive.width(context, 100),
                  margin: AppResponsive.margin(context, horizontal: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 8)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        AppResponsive.spacing(context, 8)),
                    child: _buildCarouselImage(imageUrl),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCarouselImage(String imageUrl) {
    // Check if it's a URL or local asset
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return _buildNetworkImage(imageUrl);
    } else {
      // Local asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.none,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.values.first,
      placeholder: (context, url) => _buildGradientPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      // Optimize memory usage with smaller cache sizes
      memCacheWidth: 600,
      memCacheHeight: 400,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 600,
      // Add performance optimizations
      useOldImageOnUrlChange: true,
      filterQuality: FilterQuality.low, // Faster rendering for carousel
    );
  }

  Widget _buildGradientPlaceholder() {
    final startColor = widget.gradientStartColor ?? Colors.pink.shade100;
    final endColor = widget.gradientEndColor ?? Colors.pink.shade300;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            startColor,
            Color.lerp(startColor, endColor, 0.5)!,
            endColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerEffect(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Loading...',
                style: TextStyle(
                  color: endColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.8),
            (widget.gradientStartColor ?? Colors.pink.shade100)
                .withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.image,
        size: 30,
        color: widget.gradientEndColor ?? Colors.pink.shade400,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
