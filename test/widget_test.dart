import 'package:flutter_test/flutter_test.dart';
import 'package:eduquiz_interactive/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const EduQuizApp());

    // cek apakah login muncul
    expect(find.text('EduQuiz Interactive'), findsOneWidget);
  });
}
