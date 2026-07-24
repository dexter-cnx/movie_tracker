import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class ReleaseCalendarPage extends StatelessWidget {
  const ReleaseCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    const days = [
      'Mon 17',
      'Tue 18',
      'Wed 19',
      'Thu 20',
      'Fri 21',
      'Sat 22',
      'Sun 23',
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'releaseCalendar'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'november2026'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final isSelected = index == 2;
                  return Container(
                    width: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.button : AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      days[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppColors.onButton : AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _event(
              context,
              time: '9:15 AM',
              title: 'Dune: Part Two',
              status: 'inTheaters'.tr(),
              overview:
                  'A cinematic return to Arrakis with a large-format release and an ensemble cast.',
            ),
            _event(
              context,
              time: '1:30 PM',
              title: 'Inside Out 2',
              status: 'watched'.tr(),
              overview:
                  'A colorful emotional adventure with a warm, character-driven story.',
            ),
            _event(
              context,
              time: '6:45 PM',
              title: 'Upcoming Marvels',
              status: 'upcoming'.tr(),
              overview:
                  'A curated look at upcoming superhero releases and announced production windows.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _event(
    BuildContext context, {
    required String time,
    required String title,
    required String status,
    required String overview,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    overview,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Align(
                        widthFactor: .72,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardAlt,
                            border: Border.all(
                              color: AppColors.card,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
