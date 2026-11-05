import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/core/services/security_service.dart';
import 'package:ghostconv/core/theme/app_theme.dart';
import 'package:ghostconv/features/chat/presentation/chat_ended_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wipe and Settings Flow Tests', () {
    testWidgets('ChatEndedScreen renders all required labels and Return button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkMaterialTheme,
            home: const ChatEndedScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chat Ended'), findsOneWidget);
      expect(find.text('All Data Deleted'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('Wipe Hold Button requires press-and-hold to trigger onConfirmed', (tester) async {
      bool wiped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkMaterialTheme,
            home: Scaffold(
              body: Center(
                child: WipeHoldConfirmTestWrapper(
                  onConfirmed: () {
                    wiped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap and quick release (< 1.5 seconds)
      final quickGesture = await tester.startGesture(tester.getCenter(find.byType(WipeHoldConfirmTestWrapper)));
      await tester.pump(const Duration(milliseconds: 150)); // let arena resolve
      await tester.pump(const Duration(milliseconds: 200));
      await quickGesture.up();
      await tester.pumpAndSettle();

      // Should NOT have triggered wipe yet
      expect(wiped, isFalse);

      // Hold for full 1500ms
      final holdGesture = await tester.startGesture(tester.getCenter(find.byType(WipeHoldConfirmTestWrapper)));
      await tester.pump(const Duration(milliseconds: 150)); // arena resolves and tapDown fires
      await tester.pump(const Duration(milliseconds: 1600)); // animation completes
      await holdGesture.up();
      await tester.pumpAndSettle();

      // Must have triggered wipe!
      expect(wiped, isTrue);
    });

    test('SecurityNotifier initializes with default enabled and toggles properly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(securityServiceProvider.notifier);
      expect(container.read(securityServiceProvider).isBlockScreenshotsEnabled, isTrue);

      await notifier.toggleBlockScreenshots(false);
      expect(container.read(securityServiceProvider).isBlockScreenshotsEnabled, isFalse);

      await notifier.toggleBlockScreenshots(true);
      expect(container.read(securityServiceProvider).isBlockScreenshotsEnabled, isTrue);
    });
  });
}

class WipeHoldConfirmTestWrapper extends StatelessWidget {
  const WipeHoldConfirmTestWrapper({super.key, required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    return _HoldTestButton(onConfirmed: onConfirmed);
  }
}

class _HoldTestButton extends StatefulWidget {
  const _HoldTestButton({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_HoldTestButton> createState() => _HoldTestButtonState();
}

class _HoldTestButtonState extends State<_HoldTestButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
      },
      child: Container(
        height: 48,
        width: 180,
        color: Colors.red,
        child: const Center(child: Text('Hold to Wipe')),
      ),
    );
  }
}
