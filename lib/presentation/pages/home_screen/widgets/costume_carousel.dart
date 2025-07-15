import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lotto_app/core/utils/responsive_helper.dart';

class SimpleCarouselWidget extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onImageTap;
  final double? height;
  final double? viewportFraction;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final List<String> fallbackImages;

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
    this.fallbackImages = const [
      'assets/images/five.jpeg',
      'assets/images/four.jpeg',
      'assets/images/seven.jpeg',
      'assets/images/six.jpeg',
      'assets/images/tree.jpeg',
    ],
  });

  @override
  State<SimpleCarouselWidget> createState() => _SimpleCarouselWidgetState();
}

class _SimpleCarouselWidgetState extends State<SimpleCarouselWidget> {
  // In-memory cache for loaded images
  static final Map<String, ImageProvider> _imageCache = {};

  List<String> get _displayImages {
    return widget.images.isNotEmpty ? widget.images : widget.fallbackImages;
  }

  @override
  Widget build(BuildContext context) {
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
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildNetworkImage(String imageUrl) {
    // Use cached image if available
    if (_imageCache.containsKey(imageUrl)) {
      return Image(
        image: _imageCache[imageUrl]!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Cache the successful image
          _imageCache[imageUrl] = NetworkImage(imageUrl);
          return _buildFadeInImage(child);
        }
        return _buildGradientPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildFadeInImage(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, opacity, _) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Container(
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
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
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
          const SizedBox(height: 16),
          // Fallback to default asset
          if (widget.fallbackImages.isNotEmpty)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.fallbackImages.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up cache if needed (optional)
    // _imageCache.clear();
    super.dispose();
  }
}