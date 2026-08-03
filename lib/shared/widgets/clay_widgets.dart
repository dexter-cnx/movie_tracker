import 'package:flutter/material.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/shared/widgets/app_image.dart';

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: .035)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.card,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class ClayIconButton extends StatelessWidget {
  const ClayIconButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.cardAlt,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .05)),
            ),
            child: Icon(icon, color: AppColors.text, size: 19),
          ),
        ),
      );
}

class Poster extends StatelessWidget {
  const Poster({
    super.key,
    this.path,
    this.width = 120,
    this.height = 170,
    this.radius = 18,
    this.title,
    this.heroTag,
  });

  final String? path;
  final double width, height, radius;
  final String? title;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final normalizedPath = path?.trim();
    final url = normalizedPath == null || normalizedPath.isEmpty
        ? null
        : 'https://image.tmdb.org/t/p/w500$normalizedPath';

    final fallback = Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          title ?? '🎬',
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: AppColors.cardAlt,
          child: url == null
              ? fallback
              : AppImage.network(
                  url,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  heroTag: heroTag,
                  errorWidget: fallback,
                ),
        ),
      ),
    );
  }
}
