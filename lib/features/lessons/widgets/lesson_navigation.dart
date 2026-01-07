import 'package:flutter/material.dart';

class LessonNavigation extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool hasPrevious;
  final bool hasNext;
  final String nextLabel;
  final String previousLabel;

  const LessonNavigation({
    super.key,
    this.onPrevious,
    this.onNext,
    this.hasPrevious = true,
    this.hasNext = true,
    this.nextLabel = 'Leçon suivante',
    this.previousLabel = 'Précédent',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: ElevatedButton(
              onPressed: hasPrevious ? onPrevious : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPrevious ? Colors.grey[100] : Colors.grey[50],
                foregroundColor: hasPrevious ? Colors.grey[700] : Colors.grey[400],
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 20),
                  SizedBox(width: 4),
                  Text(
                    previousLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          
          // Next button
          Expanded(
            child: ElevatedButton(
              onPressed: hasNext ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasNext ? Color(0xFF00D563) : Colors.grey[50],
                foregroundColor: hasNext ? Colors.white : Colors.grey[400],
                elevation: hasNext ? 1 : 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
