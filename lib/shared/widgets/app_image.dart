import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage.network(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.borderRadius,
    this.isCircle = false,
    this.heroTag,
    this.enableZoom = false,
    this.clearMemoryCacheWhenDispose = false,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? radius;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final Object? heroTag;
  final bool enableZoom;
  final bool clearMemoryCacheWhenDispose;
  final Widget? placeholder;
  final Widget? errorWidget;

  BorderRadius? get _resolvedBorderRadius {
    if (isCircle) return null;
    if (borderRadius != null) return borderRadius;
    if (radius != null) return BorderRadius.circular(radius!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) return _buildError();

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = _toCacheDimension(width, dpr);
    final cacheHeight = isCircle
        ? cacheWidth
        : _toCacheDimension(height, dpr);

    Widget image = ExtendedImage.network(
      normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: _resolvedBorderRadius,
      cache: true,
      cacheMaxAge: const Duration(days: 30),
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      clearMemoryCacheWhenDispose: clearMemoryCacheWhenDispose,
      clearMemoryCacheIfFailed: true,
      retries: 2,
      timeRetry: const Duration(milliseconds: 400),
      mode: enableZoom
          ? ExtendedImageMode.gesture
          : ExtendedImageMode.none,
      initGestureConfigHandler: enableZoom
          ? (_) => GestureConfig(
                minScale: 1,
                maxScale: 4,
                animationMinScale: 0.8,
                animationMaxScale: 4.5,
                cacheGesture: false,
              )
          : null,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return _buildPlaceholder();
          case LoadState.completed:
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 200),
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: child,
              ),
              child: ExtendedRawImage(
                image: state.extendedImageInfo?.image,
                width: width,
                height: height,
                fit: fit,
              ),
            );
          case LoadState.failed:
            return _buildError();
        }
      },
    );

    if (heroTag case final tag?) {
      image = Hero(
        tag: tag,
        transitionOnUserGestures: true,
        child: image,
      );
    }

    return image;
  }

  int? _toCacheDimension(double? logicalSize, double dpr) {
    if (logicalSize == null ||
        !logicalSize.isFinite ||
        logicalSize <= 0) {
      return null;
    }

    return (logicalSize * dpr).round().clamp(1, 4096);
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: _resolvedBorderRadius,
          ),
        );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: _resolvedBorderRadius,
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: _errorIconSize,
            color: AppColors.secondary,
          ),
        );
  }

  double get _errorIconSize {
    final availableSize = width ?? height ?? 40;
    return (availableSize * 0.3).clamp(20, 48);
  }
}
