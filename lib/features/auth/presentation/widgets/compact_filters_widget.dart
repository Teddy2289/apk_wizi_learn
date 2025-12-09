import 'package:flutter/material.dart';

/// Widget de filtres compacts pour le classement (2 lignes comme React)
/// Ligne 1 : Période + Recherche  
/// Ligne 2 : Formation + Formateur + Tri + Réinitialiser
class CompactFiltersWidget extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne 1 : Période + Recherche
        Row(
          children: [
            // Filtres période
            Wrap(
              spacing: 8,
              children: [
                _buildPeriodChip(context, 'Semaine', 'week'),
                _buildPeriodChip(context, 'Mois', 'month'),
                _buildPeriodChip(context, 'Tout', 'all'),
              ],
            ),
            const SizedBox(width: 12),
            // Barre de recherche
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ligne 2 : Formation + Formateur + Tri
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Formation dropdown
            _buildCompactDropdown(
              context,
              value: selectedFormation,
              hint: 'Toutes formations',
              items: formations,
              onChanged: onFormationChanged,
            ),

            // Formateur dropdown
            _buildCompactDropdown(
              context,
              value: selectedFormateur,
              hint: 'Tous formateurs',
              items: formateurs,
              onChanged: onFormateurChanged,
            ),

            // Séparateur
            Container(
              height: 20,
              width: 1,
              color: Colors.grey[300],
            ),

            // Tri par
            _buildCompactDropdown(
              context,
              value: sortBy,
              hint: 'Trier par',
              items: sortOptions,
              onChanged: (val) => onSortChanged(val ?? 'rang'),
              showValue: true,
            ),

            // Bouton ordre
            InkWell(
              onTap: onSortOrderToggle,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Bouton réinitialiser si filtres actifs
            if (hasActiveFilters) ...[
              Container(
                height: 20,
                width: 1,
                color: Colors.grey[300],
              ),
              InkWell(
                onTap: onResetFilters,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 12, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Réinit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, String value) {
    final isSelected = selectedPeriod == value;
    
    return InkWell(
      onTap: () => onPeriodChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown(
    BuildContext context, {
    required String? value,
    required String hint,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    bool showValue = false,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(hint, style: const TextStyle(fontSize: 12))),
            ...items.map((item) => DropdownMenuItem(
              value: item['id'].toString(),
              child: Text(
                showValue ? item['value'] ?? item['label'] : item['label'],
                style: const TextStyle(fontSize: 12),
              ),
            )),
          ],
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
          isDense: true,
          style: TextStyle(fontSize: 12, color: Colors.grey[900]),
        ),
      ),
    );
  }
}
