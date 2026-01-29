import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/agenda_model.dart';
import 'package:wizi_learn/features/formateur/data/services/google_calendar_service.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:intl/intl.dart';

class AgendaSection extends StatefulWidget {
  final List<AgendaEvent> events;
  final VoidCallback onRefreshRequested;

  const AgendaSection({
    super.key,
    required this.events,
    required this.onRefreshRequested,
  });

  @override
  State<AgendaSection> createState() => _AgendaSectionState();
}

class _AgendaSectionState extends State<AgendaSection> {
  late final GoogleCalendarService _calendarService;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _calendarService = GoogleCalendarService(apiClient: apiClient);
  }

  /// Handle Google Calendar Sync
  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      await _calendarService.syncWithBackend();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Calendrier synchronisé avec succès'),
            backgroundColor: FormateurTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh the agenda data
        widget.onRefreshRequested();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de synchronisation: ${e.toString()}'),
            backgroundColor: FormateurTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sort by date and take top 3 upcoming
    final upcomingEvents = widget.events
        .where((e) => e.isUpcoming || e.isToday)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    
    final displayEvents = upcomingEvents.take(3).toList();

    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: FormateurTheme.accentDark, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'AGENDA',
                    style: TextStyle(
                      color: FormateurTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (displayEvents.isEmpty)
             _buildNoUpcomingEvents()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildEventItem(displayEvents[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FormateurTheme.textTertiary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 32, color: FormateurTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun événement',
            style: TextStyle(
              color: FormateurTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les événements de votre agenda s\'afficheront ici une fois synchronisés.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FormateurTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingEvents() {
    return const Padding(
       padding: EdgeInsets.symmetric(vertical: 16),
       child: Center(
         child: Text(
           'Aucun événement à venir',
           style: TextStyle(
             color: FormateurTheme.textTertiary,
             fontSize: 14,
             fontWeight: FontWeight.w600
           )
         ),
       ),
    );
  }

  Widget _buildEventItem(AgendaEvent event) {
    final dateFormat = DateFormat('EEE d MMM', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FormateurTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FormateurTheme.border),
            ),
            child: Column(
              children: [
                Text(
                  dateFormat.format(event.start).split(' ')[1], // Day number
                  style: const TextStyle(
                    color: FormateurTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  dateFormat.format(event.start).split(' ')[2].toUpperCase(), // Month
                  style: const TextStyle(
                    color: FormateurTheme.accentDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: FormateurTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: FormateurTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}',
                      style: const TextStyle(
                        color: FormateurTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
