import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../providers.dart';

const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekMinutesAsync = ref.watch(weekMinutesProvider);
    final weekMinutes = weekMinutesAsync.value ?? List.filled(7, 0);
    final totalMinutes = ref.watch(weekTotalMinutesProvider);
    final streakAsync = ref.watch(streakProvider);
    final streak = streakAsync.value ?? 0;
    final goalTimesAsync = ref.watch(weekGoalTimeProvider);
    final goalTimes = goalTimesAsync.value ?? [];

    final focusTimeFormatted = totalMinutes >= 60
        ? '${totalMinutes ~/ 60} h ${(totalMinutes % 60).toString().padLeft(2, '0')}'
        : '$totalMinutes min';

    final maxMinute = weekMinutes.fold(0, math.max);
    final todayIndex = DateTime.now().weekday - 1;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Cette semaine',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                label: 'Temps de focus',
                value: focusTimeFormatted,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Kpi(
                label: 'Série en cours',
                value: '$streak jour${streak > 1 ? 's' : ''}',
                color: AppColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Minutes par jour', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _days.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (weekMinutes[i] > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${weekMinutes[i]}m',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              Container(
                                height: maxMinute == 0
                                    ? 6.0
                                    : (weekMinutes[i] / maxMinute * 110).clamp(
                                        6.0,
                                        110.0,
                                      ),
                                decoration: BoxDecoration(
                                  color: i == todayIndex
                                      ? AppColors.accent
                                      : (weekMinutes[i] > 0
                                            ? AppColors.done
                                            : AppColors.track),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _days[i],
                                style: TextStyle(
                                  color: i == todayIndex
                                      ? AppColors.accent
                                      : AppColors.muted,
                                  fontWeight: i == todayIndex
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Par objectif', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              if (goalTimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucune session associée cette semaine',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                )
              else
                for (final stat in goalTimes)
                  _Line(
                    stat.title,
                    stat.totalMinutes >= 60
                        ? '${stat.totalMinutes ~/ 60} h ${(stat.totalMinutes % 60).toString().padLeft(2, '0')}'
                        : '${stat.totalMinutes} min',
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: AppColors.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
