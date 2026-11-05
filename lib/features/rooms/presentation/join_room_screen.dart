import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/code_input_field.dart';
import '../../../core/widgets/ghost_button.dart';
import 'room_controller.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final GlobalKey<CodeInputFieldState> _codeKey = GlobalKey<CodeInputFieldState>();
  String _enteredCode = '';
  String? _localError;

  Future<void> _handleJoin(String code) async {
    setState(() => _localError = null);

    final cleanCode = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanCode.length != 8) {
      setState(() => _localError = 'Please enter all 8 characters.');
      _codeKey.currentState?.triggerShake();
      return;
    }

    final room = await ref.read(roomControllerProvider.notifier).joinRoom(cleanCode);

    if (room != null && mounted) {
      HapticFeedback.heavyImpact();
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Joined Successfully!'),
          description: Text('Entered ${room.name ?? "Temporary Room"}'),
        ),
      );
      context.go('/chat/${room.id}');
    } else {
      _codeKey.currentState?.triggerShake();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final roomState = ref.watch(roomControllerProvider);
    final errorMessage = _localError ?? roomState.errorMessage;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Join Room'),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft),
          onPressed: () {
            ref.read(roomControllerProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Key Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withAlpha(80)),
                  ),
                  child: Center(
                    child: Icon(LucideIcons.keyRound, size: 36, color: AppColors.accent),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Enter 8-Digit Code',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the single-use code shared by your friend to unlock the temporary chat room.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.muted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // 8-Box Code Input Field
              CodeInputField(
                key: _codeKey,
                hasError: errorMessage != null,
                errorMessage: errorMessage,
                onChanged: (val) {
                  setState(() {
                    _enteredCode = val;
                    if (_localError != null) _localError = null;
                  });
                },
                onCompleted: (code) => _handleJoin(code),
              ),

              const SizedBox(height: 28),

              // Join Button
              GhostButton(
                label: 'Join Chat Room',
                isFullWidth: true,
                height: 52,
                isLoading: roomState.isLoading,
                variant: GhostButtonVariant.primary,
                onPressed: _enteredCode.length == 8 ? () => _handleJoin(_enteredCode) : null,
              ),

              const SizedBox(height: 20),

              // Quick Paste Shortcut
              Center(
                child: TextButton.icon(
                  icon: Icon(LucideIcons.clipboard, size: 16),
                  label: const Text('Paste from Clipboard'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _codeKey.currentState?.setCode(data!.text!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
