import 'package:flutter_test/flutter_test.dart';
import 'package:draw_battle/main.dart';

void main() {
  testWidgets('DrawBattleApp build smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DrawBattleApp());

    // Verify that the App name is present on the screen or it renders the splash screen
    expect(find.text('DrawBattle'), findsWidgets);
  });
}
