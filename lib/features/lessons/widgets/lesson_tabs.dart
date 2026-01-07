import 'package:flutter/material.dart';

class LessonTabs extends StatefulWidget {
  final Widget? notesContent;
  final Widget? resourcesContent;

  const LessonTabs({
    super.key,
    this.notesContent,
    this.resourcesContent,
  });

  @override
  State<LessonTabs> createState() => _LessonTabsState();
}

class _LessonTabsState extends State<LessonTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab buttons
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildTab('Notes de leçon', 0),
              _buildTab('Ressources', 1),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Tab content
        _selectedIndex == 0
            ? (widget.notesContent ?? _defaultNotesContent())
            : (widget.resourcesContent ?? _defaultResourcesContent()),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Color(0xFF00D563) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Color(0xFF00D563) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _defaultNotesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voici les points clés de cette leçon. Concentrez-vous sur le vocabulaire des lieux et les expressions courantes pour demander et donner des indications.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        _buildBullet('Où est la bibliothèque?', 'Where is the library?'),
        _buildBullet('Tournez à gauche/droite', 'Turn left/right'),
        _buildBullet('Continuez tout droit', 'Continue straight ahead'),
        _buildBullet('C\'est près d\'ici', 'It\'s near here'),
        SizedBox(height: 16),
        Text(
          'Pratiquez ces phrases avec un partenaire. Vous pouvez trouver plus d\'exercices dans l\'onglet Ressources.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String phrase, String translation) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey[400])),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                children: [
                  TextSpan(
                    text: phrase,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' - $translation'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultResourcesContent() {
    return Text(
      'Les ressources et matériels supplémentaires apparaîtront ici.',
      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
    );
  }
}
