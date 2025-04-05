import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakCongratsSheet extends StatelessWidget {
  final int currentStreak;
  final List<DateTime> milestones;

  const StreakCongratsSheet({
    super.key,
    required this.currentStreak,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Icon(
            Icons.local_fire_department,
            color: Colors.deepOrange,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            'Congratulations!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'You\'ve completed your daily goal of 20 cards!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Current streak: $currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 30),
          if (milestones.isNotEmpty) _buildTimelineView(context),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text('Keep Learning'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context) {
    final displayedMilestones = milestones.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
          child: Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayedMilestones.length,
            itemBuilder: (context, index) {
              final milestone = displayedMilestones[index];
              final isLast = index == displayedMilestones.length - 1;

              // Calculate day number for this milestone
              int dayNumber = 0;
              if (index == 0) {
                dayNumber = 1;
              } else if (index == 1) {
                dayNumber = 3;
              } else if (index == 2) {
                dayNumber = 7;
              } else if (index == 3) {
                dayNumber = 10;
              } else {
                dayNumber = 14;
              }

              // If this is today and we have the current streak
              if (index == displayedMilestones.length - 1 &&
                  _isToday(milestone)) {
                dayNumber = currentStreak;
              }

              return Row(
                children: [
                  _buildTimelineItem(
                    context,
                    DateFormat('MMM d').format(milestone),
                    dayNumber.toString(),
                    isLast,
                  ),
                  if (!isLast)
                    Container(
                      width: 30,
                      height: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, String date, String day, bool isLast) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLast
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isLast
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
