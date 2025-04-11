import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocafusion/screens/learning_screen/learning_screen.dart';

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
        color: Color(0xffF6F3F0),
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
          Center(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blueGrey,
                  width: 4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                currentStreak.toString(),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Continue your Streak!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 30),
          if (milestones.isNotEmpty) _buildTimelineView(context),
          const SizedBox(height: 30),
          FloatingCheckingButton(
              checkIfVisible: () {
                return true;
              },
              onPressed: () async {},
              label: "I'll practice Now!"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context) {
    // Define the streak milestones
    final List<int> streakMilestones = [3, 5, 10, 20, 30, 45, 60, 90, 120];

    // Find the next milestone to achieve
    int nextMilestone = streakMilestones.firstWhere(
        (milestone) => milestone > currentStreak,
        orElse: () => streakMilestones.last);

    // Find the previous milestone (to show progress between two points)
    int previousMilestone = currentStreak;
    for (int i = streakMilestones.length - 1; i >= 0; i--) {
      if (streakMilestones[i] < currentStreak) {
        previousMilestone = streakMilestones[i];
        break;
      }
    }
    if (previousMilestone == currentStreak &&
        streakMilestones.first > currentStreak) {
      previousMilestone = 0;
    }

    // Calculate progress between current milestones
    double progressValue = (currentStreak - previousMilestone) /
        (nextMilestone - previousMilestone);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xffF9F7F5),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '$nextMilestone-day streak challenge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),

              // Previous milestone marker
              Positioned(
                left: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text(
                    previousMilestone.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2F3A4B),
                    ),
                  )),
                ),
              ),

              // Next milestone marker
              Positioned(
                right: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text(
                    nextMilestone.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2F3A4B),
                    ),
                  )),
                ),
              ),

              // Current streak marker
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text(
                    currentStreak.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )),
                ),
              )
            ],
          )
        ],
      ),
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
