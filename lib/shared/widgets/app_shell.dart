import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/connectivity/connectivity_service.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  static const double navigationContentHeight = 64;

  final Widget child;

  int _index(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/watchlist')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _index(GoRouterState.of(context).uri.path);
    final networkStatus = ref.watch(networkStatusProvider);
    final offline = networkStatus.valueOrNull == NetworkStatus.offline;

    return Scaffold(
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: offline
                ? Material(
                    key: const ValueKey('offline-banner'),
                    color: AppColors.orange,
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 18,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'networkOffline'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('online-space')),
          ),
          Expanded(child: child),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: index,
        onSelected: (route) => context.go(route),
      ),
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.button,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          tooltip: 'search'.tr(),
          onPressed: () => context.go('/explore'),
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.onButton,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF20B0B0B),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: .7),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(
            bottom: 2,
          ),
          child: SizedBox(
            height: AppShell.navigationContentHeight,
            child: Row(
              children: [
                _item(0, Icons.home_filled, 'home'.tr(), '/'),
                _item(
                  1,
                  Icons.explore_rounded,
                  'explore'.tr(),
                  '/explore',
                ),
                _item(
                  2,
                  Icons.bookmark_rounded,
                  'watchlist'.tr(),
                  '/watchlist',
                ),
                _item(
                  3,
                  Icons.person_rounded,
                  'profile'.tr(),
                  '/profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final selected = index == selectedIndex;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: () => onSelected(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.text : AppColors.muted,
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.1,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.text : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
