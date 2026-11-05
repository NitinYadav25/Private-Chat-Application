import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/core/theme/app_theme.dart';
import 'package:ghostconv/core/widgets/chat_bubble.dart';
import 'package:ghostconv/core/widgets/code_input_field.dart';
import 'package:ghostconv/core/widgets/ghost_button.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMaterialTheme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('GhostButton renders label and triggers callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      createTestWidget(
        GhostButton(
          label: 'Test Button',
          onPressed: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    await tester.tap(find.text('Test Button'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('CodeInputField renders 8 boxes and accepts input', (tester) async {
    String completedCode = '';

    await tester.pumpWidget(
      createTestWidget(
        CodeInputField(
          autofocus: false,
          onCompleted: (code) => completedCode = code,
        ),
      ),
    );

    // Verify 8 text fields exist
    expect(find.byType(TextField), findsNWidgets(8));

    // Enter a single character in the first box
    await tester.enterText(find.byType(TextField).first, 'K');
    await tester.pumpAndSettle();
    expect(completedCode, isEmpty);
  });

  testWidgets('ChatBubble displays sent and received styling', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const Column(
          children: [
            ChatBubble(
              message: 'Hello World',
              isMe: true,
              timestamp: '10:00 AM',
              status: MessageDeliveryStatus.seen,
            ),
            ChatBubble(
              message: 'Hi there',
              isMe: false,
              timestamp: '10:01 AM',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('10:01 AM'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
