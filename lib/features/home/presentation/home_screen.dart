import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/ghost_button.dart';
import '../../../core/widgets/room_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../rooms/data/room_repository.dart';
import '../../rooms/domain/room_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ghostColors;
    final authState = ref.watch(authControllerProvider);
    final userId = authState.user?.id ?? '';
    final userName = authState.user?.name ?? 'Ghost User';
    final currentTheme = ref.watch(themeModeProvider);
    final isDark = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.sentBubbleGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $userName',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                Text(
                  'GhostConv Active',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, size: 20),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            tooltip: 'Settings & Profile',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.palette, size: 20),
            tooltip: 'Design Preview',
            onPressed: () => context.push('/preview'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Action Cards: Create Room & Join Room
            Row(
              children: [
                // Create Room Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/rooms/create'),
                    child: Container(
                      height: 130,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.sentBubbleGradient,
                        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                        boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Room',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Get 8-char code',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppConstants.space12),

                // Join Room Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/rooms/join'),
                    child: Container(
                      height: 130,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.keyRound, color: AppColors.accent, size: 20),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Join Room',
                                style: AppTypography.titleLarge.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Enter 8-box code',
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.space24),

            // Active Rooms Stream List
            StreamBuilder<List<RoomModel>>(
              stream: ref.watch(roomRepositoryProvider).watchUserRooms(userId),
              builder: (context, snapshot) {
                final rooms = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Temporary Rooms',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        Text(
                          '${rooms.length} Active',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space16),
                    if (rooms.isEmpty)
                      _buildEmptyRoomsState(colors)
                    else
                      ...rooms.map(
                        (room) => RoomCard(
                          roomId: room.id,
                          roomCode: room.code ?? '8-CHAR',
                          roomName: room.name ?? 'Private Room',
                          status: room.isWaiting ? RoomStatus.waiting : RoomStatus.active,
                          onTap: () => context.go('/chat/${room.id}'),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Quick Link to Design Preview
            GhostButton(
              label: 'Open Design System Preview',
              icon: const Icon(LucideIcons.sparkles, size: 18),
              variant: GhostButtonVariant.outline,
              isFullWidth: true,
              onPressed: () => context.push('/preview'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoomsState(GhostConvColors colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.elevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(LucideIcons.messageSquareDashed, size: 30, color: colors.muted),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Rooms',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a room to invite a friend with an 8-character code, or enter an existing code to join.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: colors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
