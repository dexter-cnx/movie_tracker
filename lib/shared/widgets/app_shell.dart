import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _index(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/watchlist')) return 2;
    if (location.startsWith('/calendar')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _index(GoRouterState.of(context).uri.path);
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xF20B0B0B),
          border: Border(top: BorderSide(color: AppColors.divider, width: .7)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _item(context, 0, index, Icons.home_filled, 'home'.tr(), '/'),
              _item(context, 1, index, Icons.explore_rounded, 'explore'.tr(), '/explore'),
              _item(context, 2, index, Icons.bookmark_rounded, 'watchlist'.tr(), '/watchlist'),
              _item(context, 3, index, Icons.calendar_month_rounded, 'calendar'.tr(), '/calendar'),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.button,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.onButton, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _item(BuildContext context, int i, int selected, IconData icon, String label, String route) => Expanded(
        child: InkWell(
          onTap: () => context.go(route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: i == selected ? AppColors.text : AppColors.muted, size: 21),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: i == selected ? AppColors.text : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
}
