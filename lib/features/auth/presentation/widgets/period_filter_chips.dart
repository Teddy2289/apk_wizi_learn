import 'package:flutter/material.dart';

/// Widget pour les filtres de période du classement
class PeriodFilterChips extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodFilterChips({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'Cette semaine',
          value: 'week',
        ),
        _buildFilterChip(
          context,
          label: 'Ce mois',
          value: 'month',
        ),
        _buildFilterChip(
          context,
          label: 'Depuis toujours',
          value: 'all',
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isSelected = selectedPeriod == value;
    final primaryColor = Theme.of(context).primaryColor;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onPeriodChanged(value),
      selectedColor: primaryColor,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
