import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:dio/dio.dart';

class GoogleCalendarService {
  final ApiClient apiClient;
  
  static const List<String> _scopes = [
    calendar.CalendarApi.calendarReadonlyScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  GoogleCalendarService({required this.apiClient});

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Fetch calendar events from Google
  Future<List<calendar.Event>> fetchGoogleCalendarEvents() async {
    try {
      final account = await _googleSignIn.signInSilently() ?? await signIn();
      if (account == null) {
        throw Exception('Google Sign-In failed');
      }

      // Get authenticated HTTP client
      final authenticatedClient = await _googleSignIn.authenticatedClient();
      if (authenticatedClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final calendarApi = calendar.CalendarApi(authenticatedClient);

      // Fetch calendars
      final calendarList = await calendarApi.calendarList.list();
      final calendars = calendarList.items ?? [];

      debugPrint('📅 Found ${calendars.length} calendars');

      // Fetch events from all calendars
      final allEvents = <calendar.Event>[];
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final oneMonthLater = now.add(const Duration(days: 90));

      for (final cal in calendars) {
        if (cal.id == null) continue;

        try {
          final events = await calendarApi.events.list(
            cal.id!,
            timeMin: oneMonthAgo.toUtc(),
            timeMax: oneMonthLater.toUtc(),
            singleEvents: true,
            orderBy: 'startTime',
          );

          if (events.items != null) {
            allEvents.addAll(events.items!);
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching events for calendar ${cal.summary}: $e');
        }
      }

      debugPrint('✅ Fetched ${allEvents.length} events from Google Calendar');
      return allEvents;
    } catch (e) {
      debugPrint('❌ Error fetching Google Calendar events: $e');
      rethrow;
    }
  }

  /// Sync Google Calendar data with the backend
  Future<void> syncWithBackend() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw Exception('No Google account signed in');
      }

      // Fetch events from Google
      final googleEvents = await fetchGoogleCalendarEvents();

      // Get authenticated HTTP client
      final authenticatedClient = await _googleSignIn.authenticatedClient();
      if (authenticatedClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final calendarApi = calendar.CalendarApi(authenticatedClient);
      final calendarList = await calendarApi.calendarList.list();
      final calendars = calendarList.items ?? [];

      // Format calendars for backend
      final calendarsData = calendars.map((cal) => {
        'googleId': cal.id,
        'summary': cal.summary,
        'description': cal.description,
        'backgroundColor': cal.backgroundColor,
        'foregroundColor': cal.foregroundColor,
        'accessRole': cal.accessRole,
        'timeZone': cal.timeZone,
      }).toList();

      // Format events for backend
      final eventsData = googleEvents.map((event) {
        final start = event.start?.dateTime ?? event.start?.date;
        final end = event.end?.dateTime ?? event.end?.date;

        return {
          'googleId': event.id,
          'calendarId': event.organizer?.email ?? calendars.first.id,
          'summary': event.summary ?? 'Sans titre',
          'description': event.description,
          'location': event.location,
          'start': start?.toIso8601String(),
          'end': end?.toIso8601String(),
          'htmlLink': event.htmlLink,
          'hangoutLink': event.hangoutLink,
          'organizer': event.organizer?.email,
          'attendees': event.attendees?.map((a) => a.email).toList(),
          'status': event.status,
          'recurrence': event.recurrence,
          'eventType': event.eventType,
        };
      }).toList();

      // Send to backend using custom header
      await apiClient.post(
        '/agendas/sync',
        data: {
          'userId': await _getUserId(),
          'calendars': calendarsData,
          'events': eventsData,
        },
        options: Options(
          headers: {
            'x-sync-secret': 'wizi-calendar-sync-secret-2026-v1',
          },
        ),
      );

      debugPrint('✅ Backend sync successful');
    } catch (e) {
      debugPrint('❌ Backend sync error: $e');
      rethrow;
    }
  }

  /// Get current user ID from storage/API
  Future<String> _getUserId() async {
    try {
      final response = await apiClient.get('/me');
      return response.data['id']?.toString() ?? '0';
    } catch (e) {
      debugPrint('⚠️ Could not get user ID: $e');
      return '0';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;
}
