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
  
  // Keep alive to prevent rebuilds when scrolling in a list/tab
  @override
  bool get wantKeepAlive => true;

  // REMOVED: didUpdateWidget and _listEquals are not needed.
  // The build method is automatically called when widget.images changes.

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Return a placeholder if there are no images to prevent errors
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height ?? AppResponsive.height(context, AppResponsive.isMobile(context) ? 15 : 20),
        child: _buildGradientPlaceholder(),
      );
    }

    return Padding(
      padding: AppResponsive.padding(context, horizontal: 16, vertical: 8),
      child: CarouselSlider.builder(
        itemCount: widget.images.length,
        itemBuilder: (context, index, realIndex) {
          final imageUrl = widget.images[index];
          return GestureDetector(
            onTap: widget.onImageTap,
            child: Container(
              width: AppResponsive.width(context, 100),
              margin: AppResponsive.margin(context, horizontal: 0),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppResponsive.spacing(context, 8)),
                child: _buildCarouselImage(imageUrl),
              ),
            ),
          );
        },
        options: CarouselOptions(
          height: widget.height ??
              AppResponsive.height(
                  context, AppResponsive.isMobile(context) ? 15 : 20),
          autoPlay: widget.autoPlay,
          autoPlayInterval: widget.autoPlayInterval,
          enlargeCenterPage: true,
          viewportFraction: widget.viewportFraction ??
              (AppResponsive.isMobile(context) ? 0.85 : 0.7),
          enableInfiniteScroll: widget.images.length > 1,
          pauseAutoPlayOnTouch: true,
          pauseAutoPlayOnManualNavigate: true,
        ),
      ),
    );
  }

  Widget _buildCarouselImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return _buildNetworkImage(imageUrl);
    } else {
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
      memCacheWidth: 600,
      memCacheHeight: 400,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 600,
      useOldImageOnUrlChange: true,
      filterQuality: FilterQuality.low,
    );
  }

  // ... (Your _buildGradientPlaceholder, _buildShimmerEffect, and _buildErrorWidget methods remain the same)
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Loading...',
                style: TextStyle(
                  color: endColor.withOpacity(0.8),
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
            Colors.white.withOpacity(0.8),
            (widget.gradientStartColor ?? Colors.pink.shade100)
                .withOpacity(0.6),
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