import 'package:flutter/material.dart';
import 'lesson_progress_bar.dart';
import 'lesson_tabs.dart';
import 'lesson_navigation.dart';

class LessonInfoCard extends StatelessWidget {
  final int currentLesson;
  final int totalLessons;
  final double progress;
  final String lessonTitle;
  final Widget? customContent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool hasPrevious;
  final bool hasNext;

  const LessonInfoCard({
    Key? key,
    required this.currentLesson,
    required this.totalLessons,
    required this.progress,
    required this.lessonTitle,
    this.customContent,
    this.onPrevious,
    this.onNext,
    this.hasPrevious = true,
    this.hasNext = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LessonProgressBar(
              current: currentLesson,
              total: totalLessons,
              percentage: progress,
            ),
            SizedBox(height: 20),
            
            // Lesson title
            Text(
              lessonTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),
            SizedBox(height: 20),
            
            // Divider
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            SizedBox(height: 20),
            
            // Tabs
            LessonTabs(
              notesContent: customContent,
            ),
            
            // Navigation
            LessonNavigation(
              onPrevious: onPrevious,
              onNext: onNext,
              hasPrevious: hasPrevious,
              hasNext: hasNext,
            ),
          ],
        ),
      ),
    );
  }
}
