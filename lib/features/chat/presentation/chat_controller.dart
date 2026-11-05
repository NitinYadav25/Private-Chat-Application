import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media/data/cloudinary_repository.dart';
import '../../rooms/data/room_repository.dart';
import '../../rooms/domain/room_model.dart';
import '../data/chat_repository.dart';
import '../domain/message_model.dart';
import '../domain/presence_model.dart';

final chatControllerProvider =
    StateNotifierProvider.autoDispose.family<ChatController, ChatState, String>((ref, roomId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final roomRepo = ref.watch(roomRepositoryProvider);
  final cloudinaryRepo = ref.watch(cloudinaryRepositoryProvider);
  final currentUser = ref.watch(authControllerProvider).user;
  return ChatController(chatRepo, roomRepo, cloudinaryRepo, roomId, currentUser?.id ?? '');
});

class ChatState {
  const ChatState({
    required this.roomId,
    this.messages = const [],
    this.isLoading = true,
    this.isPartnerOnline = false,
    this.isPartnerTyping = false,
    this.replyingTo,
    this.partnerId,
    this.partnerName = 'Partner',
    this.roomCode,
    this.roomName,
    this.isMuted = false,
    this.roomStatus = RoomLifecycleStatus.active,
    this.uploadProgress = const {},
  });

  final String roomId;
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isPartnerOnline;
  final bool isPartnerTyping;
  final MessageModel? replyingTo;
  final String? partnerId;
  final String partnerName;
  final String? roomCode;
  final String? roomName;
  final bool isMuted;
  final RoomLifecycleStatus roomStatus;
  final Map<String, double> uploadProgress; // msgId -> progress (0.0 to 1.0)

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isPartnerOnline,
    bool? isPartnerTyping,
    MessageModel? replyingTo,
    String? partnerId,
    String? partnerName,
    String? roomCode,
    String? roomName,
    bool? isMuted,
    RoomLifecycleStatus? roomStatus,
    Map<String, double>? uploadProgress,
    bool clearReply = false,
  }) {
    return ChatState(
      roomId: roomId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      roomCode: roomCode ?? this.roomCode,
      roomName: roomName ?? this.roomName,
      isMuted: isMuted ?? this.isMuted,
      roomStatus: roomStatus ?? this.roomStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(
    this._chatRepo,
    this._roomRepo,
    this._cloudinaryRepo,
    String roomId,
    this._currentUserId,
  ) : super(ChatState(roomId: roomId)) {
    _init();
  }

  final ChatRepository _chatRepo;
  final RoomRepository _roomRepo;
  final CloudinaryRepository _cloudinaryRepo;
  final String _currentUserId;

  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<PresenceModel?>? _presenceSub;
  StreamSubscription<RoomModel?>? _roomSub;
  Timer? _typingDebounceTimer;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, ({File file, MessageType type})> _pendingFiles = {};

  Future<void> _init() async {
    // 1. Immediately load local Hive cache for instant cold start
    final cached = await _chatRepo.loadCachedMessages(state.roomId);
    if (cached.isNotEmpty) {
      state = state.copyWith(messages: cached, isLoading: false);
    }

    // 2. Watch room document for metadata and status changes
    _roomSub = _roomRepo.watchRoom(state.roomId).listen((room) async {
      if (room == null || room.status == RoomLifecycleStatus.ended) {
        // Room ended or wiped: purge all local cache and media for this room
        await _chatRepo.clearRoomData(state.roomId);
        state = state.copyWith(roomStatus: RoomLifecycleStatus.ended);
        return;
      }

      final partnerId = room.getPartnerId(_currentUserId);
      state = state.copyWith(
        roomName: room.name,
        roomCode: room.code,
        roomStatus: room.status,
        partnerId: partnerId,
      );

      if (partnerId != null && _presenceSub == null) {
        _watchPartnerPresence(partnerId);
      }
    });

    // 3. Listen to real-time messages
    _messagesSub = _chatRepo.watchMessages(state.roomId).listen((messages) {
      // Merge real-time messages with any pending local upload messages
      final pendingSending = state.messages
          .where((m) => m.status == MessageDeliveryStatus.sending || m.status == MessageDeliveryStatus.failed)
          .where((m) => !messages.any((remote) => remote.id == m.id))
          .toList();

      state = state.copyWith(
        messages: [...messages, ...pendingSending],
        isLoading: false,
      );
      _chatRepo.markMessagesSeen(state.roomId, _currentUserId);
    });

    // 4. Mark self as online
    _chatRepo.updatePresence(state.roomId, _currentUserId, isOnline: true, isTyping: false);
  }

  void _watchPartnerPresence(String partnerId) {
    _presenceSub = _chatRepo.watchPresence(state.roomId, partnerId).listen((presence) {
      if (presence != null) {
        state = state.copyWith(
          isPartnerOnline: presence.isOnline,
          isPartnerTyping: presence.isTyping,
        );
      }
    });
  }

  void onUserTyping(String text) {
    _chatRepo.updatePresence(state.roomId, _currentUserId, isOnline: true, isTyping: true);

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
      _chatRepo.updatePresence(state.roomId, _currentUserId, isOnline: true, isTyping: false);
    });
  }

  Future<void> sendTextMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _typingDebounceTimer?.cancel();
    _chatRepo.updatePresence(state.roomId, _currentUserId, isOnline: true, isTyping: false);

    ReplyMessageModel? replyModel;
    if (state.replyingTo != null) {
      replyModel = ReplyMessageModel(
        id: state.replyingTo!.id,
        authorName: state.replyingTo!.isMe(_currentUserId) ? 'You' : state.partnerName,
        text: state.replyingTo!.text,
      );
    }

    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_$_currentUserId',
      roomId: state.roomId,
      senderId: _currentUserId,
      type: MessageType.text,
      text: clean,
      replyTo: replyModel,
      createdAt: DateTime.now(),
    );

    // Optimistically append to local state
    final updatedList = List<MessageModel>.from(state.messages)..add(message);
    state = state.copyWith(messages: updatedList, clearReply: true);

    await _chatRepo.sendMessage(message);
  }

  Future<void> sendMediaMessage(File file, MessageType type) async {
    final tempId = 'upload_${DateTime.now().millisecondsSinceEpoch}_$_currentUserId';
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    ReplyMessageModel? replyModel;
    if (state.replyingTo != null) {
      replyModel = ReplyMessageModel(
        id: state.replyingTo!.id,
        authorName: state.replyingTo!.isMe(_currentUserId) ? 'You' : state.partnerName,
        text: state.replyingTo!.text,
      );
    }

    // 1. Optimistic message placeholder with local file preview
    final optimisticMessage = MessageModel(
      id: tempId,
      roomId: state.roomId,
      senderId: _currentUserId,
      type: type,
      text: fileName,
      mediaUrl: file.path,
      fileName: fileName,
      fileSize: fileSize,
      status: MessageDeliveryStatus.sending,
      replyTo: replyModel,
      createdAt: DateTime.now(),
    );

    _pendingFiles[tempId] = (file: file, type: type);
    final cancelToken = CancelToken();
    _cancelTokens[tempId] = cancelToken;

    final updatedProgress = Map<String, double>.from(state.uploadProgress)..[tempId] = 0.05;
    final updatedMessages = List<MessageModel>.from(state.messages)..add(optimisticMessage);
    state = state.copyWith(
      messages: updatedMessages,
      uploadProgress: updatedProgress,
      clearReply: true,
    );

    // 2. Perform signed Cloudinary upload
    final resourceType = type == MessageType.image
        ? 'image'
        : (type == MessageType.video ? 'video' : 'raw');

    try {
      final uploadResult = await _cloudinaryRepo.uploadMedia(
        roomId: state.roomId,
        file: file,
        resourceType: resourceType,
        cancelToken: cancelToken,
        onProgress: (progress) {
          final pMap = Map<String, double>.from(state.uploadProgress)..[tempId] = progress;
          state = state.copyWith(uploadProgress: pMap);
        },
      );

      // 3. Upload completed: replace optimistic message with remote message
      _cancelTokens.remove(tempId);
      _pendingFiles.remove(tempId);
      final finalProgress = Map<String, double>.from(state.uploadProgress)..remove(tempId);

      final realMessage = MessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_$_currentUserId',
        roomId: state.roomId,
        senderId: _currentUserId,
        type: type,
        text: fileName,
        mediaUrl: uploadResult.url,
        mediaPublicId: uploadResult.publicId,
        resourceType: uploadResult.resourceType,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        thumbnailUrl: uploadResult.thumbnailUrl,
        replyTo: replyModel,
        status: MessageDeliveryStatus.sent,
        createdAt: DateTime.now(),
      );

      final cleanMessages = state.messages.where((m) => m.id != tempId).toList()..add(realMessage);
      state = state.copyWith(
        messages: cleanMessages,
        uploadProgress: finalProgress,
      );

      await _chatRepo.sendMessage(realMessage);
    } catch (_) {
      _cancelTokens.remove(tempId);
      final failedProgress = Map<String, double>.from(state.uploadProgress)..remove(tempId);
      final markedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: MessageDeliveryStatus.failed);
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: markedMessages,
        uploadProgress: failedProgress,
      );
    }
  }

  void retryUpload(String tempId) {
    final pending = _pendingFiles[tempId];
    if (pending != null) {
      removeMessage(tempId);
      sendMediaMessage(pending.file, pending.type);
    }
  }

  void cancelUpload(String tempId) {
    _cancelTokens[tempId]?.cancel('User cancelled upload');
    _cancelTokens.remove(tempId);
    _pendingFiles.remove(tempId);
    final pMap = Map<String, double>.from(state.uploadProgress)..remove(tempId);
    final clean = state.messages.where((m) => m.id != tempId).toList();
    state = state.copyWith(messages: clean, uploadProgress: pMap);
  }

  void removeMessage(String messageId) {
    final clean = state.messages.where((m) => m.id != messageId).toList();
    state = state.copyWith(messages: clean);
  }

  void setReplyingTo(MessageModel? message) {
    state = state.copyWith(replyingTo: message);
  }

  void cancelReply() {
    state = state.copyWith(clearReply: true);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> endChatAndWipe() async {
    // Purge local cache and media
    await _chatRepo.clearRoomData(state.roomId);
    state = state.copyWith(roomStatus: RoomLifecycleStatus.ended);

    // Trigger server wipe
    await _roomRepo.wipeRoom(state.roomId);
  }

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('Chat controller disposed');
    }
    _cancelTokens.clear();
    _messagesSub?.cancel();
    _presenceSub?.cancel();
    _roomSub?.cancel();
    _typingDebounceTimer?.cancel();
    _chatRepo.updatePresence(state.roomId, _currentUserId, isOnline: false, isTyping: false);
    super.dispose();
  }
}
