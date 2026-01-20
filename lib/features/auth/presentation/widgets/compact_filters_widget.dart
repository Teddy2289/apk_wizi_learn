import 'package:flutter/material.dart';

/// Widget de filtres simplifié et intuitif pour le classement
/// Conçu pour être léger et facile à utiliser
class CompactFiltersWidget extends StatefulWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? selectedFormation;
  final List<Map<String, dynamic>> formations;
  final Function(String?) onFormationChanged;
  final String? selectedFormateur;
  final List<Map<String, dynamic>> formateurs;
  final Function(String?) onFormateurChanged;
  final String sortBy;
  final List<Map<String, String>> sortOptions;
  final Function(String) onSortChanged;
  final bool sortAscending;
  final Function() onSortOrderToggle;
  final Function() onResetFilters;
  final bool hasActiveFilters;

  const CompactFiltersWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    this.selectedFormation,
    required this.formations,
    required this.onFormationChanged,
    this.selectedFormateur,
    required this.formateurs,
    required this.onFormateurChanged,
    required this.sortBy,
    required this.sortOptions,
    required this.onSortChanged,
    required this.sortAscending,
    required this.onSortOrderToggle,
    required this.onResetFilters,
    required this.hasActiveFilters,
  });

  @override
  State<CompactFiltersWidget> createState() => _CompactFiltersWidgetState();
}

class _CompactFiltersWidgetState extends State<CompactFiltersWidget> {
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  int _countActiveFilters() {
    int count = 0;
    if (widget.searchQuery.isNotEmpty) count++;
    if (widget.selectedFormation != null) count++;
    if (widget.selectedFormateur != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de recherche
            SizedBox(
              width: isMobile ? screenWidth - 32 : 260,
              height: 40,
              child: TextField(
                focusNode: _searchFocusNode,
                onChanged: widget.onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Chercher...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Period selector (Premium Segmented Control)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   _buildSegmentedButton('Semaine', widget.selectedPeriod == 'week', () => widget.onPeriodChanged('week')),
                   _buildSegmentedButton('Mois', widget.selectedPeriod == 'month', () => widget.onPeriodChanged('month')),
                   _buildSegmentedButton('Trimestre', widget.selectedPeriod == 'trimestre', () => widget.onPeriodChanged('trimestre')),
                   _buildSegmentedButton('Tout', widget.selectedPeriod == 'all', () => widget.onPeriodChanged('all')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Formation filter
            _buildSimpleDropdown(
              value: widget.selectedFormation,
              hint: 'Formation',
              items: widget.formations,
              onChanged: widget.onFormationChanged,
              icon: Icons.school,
            ),
            const SizedBox(width: 8),
            // Formateur filter
            _buildSimpleDropdown(
              value: widget.selectedFormateur,
              hint: 'Formateur',
              items: widget.formateurs,
              onChanged: widget.onFormateurChanged,
              icon: Icons.person,
            ),
            const SizedBox(width: 8),
            // Reset button
            if (widget.hasActiveFilters)
              _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown({
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final isActive = value != null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.blue[300]! : Colors.grey[300]!,
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.blue[50] : Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.blue[600] : Colors.grey[600]),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 12)),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(hint, style: const TextStyle(fontSize: 12)),
                ),
                ...items.map((item) => DropdownMenuItem(
                  value: item['id'].toString(),
                  child: Text(
                    item['label'],
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
              ],
              onChanged: onChanged,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: isActive ? Colors.blue[600] : Colors.grey[600],
              ),
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    final activeCount = _countActiveFilters();

    return InkWell(
      onTap: widget.onResetFilters,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.red[50],
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: Colors.red[600]),
            const SizedBox(width: 4),
            Text(
              activeCount > 0 ? 'Réinit. ($activeCount)' : 'Réinit.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
