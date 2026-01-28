import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/features/formateur/data/models/agenda_model.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:intl/intl.dart';

class AgendaSection extends StatelessWidget {
  final List<AgendaEvent> events;

  const AgendaSection({
    super.key,
    required this.events,
  });

  Future<void> _launchSyncApp() async {
    // URL of the Next.js Sync App
    const url = 'https://wizi-learn-google-calendar.vercel.app';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sort by date and take top 3 upcoming
    final upcomingEvents = events
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
              TextButton.icon(
                onPressed: _launchSyncApp,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('SYNCHRONISER'),
                style: TextButton.styleFrom(
                  foregroundColor: FormateurTheme.accent,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
            'Connectez votre Google Calendar pour voir vos rendez-vous ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FormateurTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _launchSyncApp,
            icon: const Icon(Icons.sync_alt, size: 18),
            label: const Text('CONNECTER GOOGLE CALENDAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FormateurTheme.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: FormateurTheme.accent.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
