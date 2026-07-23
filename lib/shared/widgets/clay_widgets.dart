import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';

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
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: .035)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: child,
      );
}

class ClayIconButton extends StatelessWidget {
  const ClayIconButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Icon(icon, color: AppColors.text, size: 19),
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
  });

  final String? path;
  final double width, height, radius;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final url = path == null ? null : 'https://image.tmdb.org/t/p/w500$path';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: AppColors.cardAlt,
          child: url == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      title ?? '🎬',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.movie_rounded, color: AppColors.secondary)),
                ),
        ),
      ),
    );
  }
}
