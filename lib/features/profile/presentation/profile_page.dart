import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/app_info/app_info_provider.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/auth/presentation/auth_controller.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(profileControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final appInfo = ref.watch(appInfoProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            ClayCard(
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.cardAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferences.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preferences.email.isEmpty
                              ? 'noEmail'.tr()
                              : preferences.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (preferences.favoriteGenre.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${'favoriteGenre'.tr()}: ${preferences.favoriteGenre}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'editProfile'.tr(),
                    onPressed: () => _editProfile(context, ref),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'account'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ClayCard(
              padding: EdgeInsets.zero,
              child: auth.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => ListTile(
                  leading: const Icon(Icons.error_outline_rounded),
                  title: Text('sessionUnavailable'.tr()),
                  subtitle: Text('signInAgain'.tr()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/login'),
                ),
                data: (session) {
                  if (session == null) {
                    return ListTile(
                      leading: const Icon(Icons.login_rounded),
                      title: Text('signIn'.tr()),
                      subtitle: Text('demoAuthenticationDescription'.tr()),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/login'),
                    );
                  }

                  final expiresAt = session.expiresAt.toLocal();
                  final materialLocalizations = MaterialLocalizations.of(context);
                  final expiry = '${materialLocalizations.formatShortDate(expiresAt)} '
                      '${materialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(expiresAt))}';

                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.verified_user_rounded),
                        title: Text(
                          'authenticatedAs'.tr(args: [session.userId]),
                        ),
                        subtitle: Text(
                          'sessionExpires'.tr(args: [expiry]),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: Text('signOut'.tr()),
                        onTap: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'settings'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ClayCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text('language'.tr()),
                    subtitle: Text(
                      preferences.languageCode == 'th'
                          ? 'thai'.tr()
                          : 'english'.tr(),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _chooseLanguage(context, ref),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_rounded),
                    title: Text('notifications'.tr()),
                    subtitle: Text('notificationsDescription'.tr()),
                    value: preferences.notificationsEnabled,
                    onChanged: ref
                        .read(profileControllerProvider.notifier)
                        .setNotificationsEnabled,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.play_circle_rounded),
                    title: Text('autoplayTrailers'.tr()),
                    subtitle: Text('autoplayTrailersDescription'.tr()),
                    value: preferences.autoplayTrailers,
                    onChanged: ref
                        .read(profileControllerProvider.notifier)
                        .setAutoplayTrailers,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'more'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ClayCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: Text('releaseCalendar'.tr()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/calendar'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text('aboutApp'.tr()),
                    subtitle: Text(
                      'appVersion'.tr(
                        args: [appInfo.valueOrNull?.displayVersion ?? '—'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('english'.tr()),
              onTap: () => Navigator.pop(context, 'en'),
            ),
            ListTile(
              title: Text('thai'.tr()),
              onTap: () => Navigator.pop(context, 'th'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await context.setLocale(Locale(selected));
    await ref.read(profileControllerProvider.notifier).setLanguage(selected);
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final current = ref.read(profileControllerProvider);
    final nameController = TextEditingController(text: current.displayName);
    final emailController = TextEditingController(text: current.email);
    final genreController = TextEditingController(text: current.favoriteGenre);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('editProfile'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'displayName'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'email'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genreController,
                decoration: InputDecoration(labelText: 'favoriteGenre'.tr()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(profileControllerProvider.notifier).updateProfile(
                    displayName: nameController.text,
                    email: emailController.text,
                    favoriteGenre: genreController.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();
    genreController.dispose();
  }
}
