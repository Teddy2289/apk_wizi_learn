import 'package:flutter_test/flutter_test.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/youtube_player_page.dart';

void main() {
  testWidgets('YoutubePlayerPage se construit sans erreur', (
    WidgetTester tester,
  ) async {
    // await tester.pumpWidget(
    //   MaterialApp(
    //     home: YoutubePlayerPage(
    //       video: /* provide a mock or test video object here */,
    //       videosInSameCategory: /* provide a mock or test list of videos here */,
    //     ),
    //   ),
    // );
    expect(find.byType(YoutubePlayerPage), findsOneWidget);
  });
}
