import 'package:flutter/material.dart';

class LessonProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final double percentage;

  const LessonProgressBar({
    Key? key,
    required this.current,
    required this.total,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress label
       Text(
          'Vous êtes à la leçon $current sur $total',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 12),
        
        // Module Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression du module',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D563),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Color(0xFFE6F9F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF00D563),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
