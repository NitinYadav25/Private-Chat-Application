import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';

final roomControllerProvider = StateNotifierProvider<RoomController, RoomState>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return RoomController(repository);
});

class RoomState {
  const RoomState({
    this.createdRoom,
    this.joinedRoom,
    this.activeRooms = const [],
    this.isLoading = false,
    this.isWakingServer = false,
    this.errorMessage,
    this.attemptsLeft,
  });

  final RoomModel? createdRoom;
  final RoomModel? joinedRoom;
  final List<RoomModel> activeRooms;
  final bool isLoading;
  final bool isWakingServer;
  final String? errorMessage;
  final int? attemptsLeft;

  RoomState copyWith({
    RoomModel? createdRoom,
    RoomModel? joinedRoom,
    List<RoomModel>? activeRooms,
    bool? isLoading,
    bool? isWakingServer,
    String? errorMessage,
    int? attemptsLeft,
    bool clearCreated = false,
    bool clearJoined = false,
    bool clearError = false,
  }) {
    return RoomState(
      createdRoom: clearCreated ? null : (createdRoom ?? this.createdRoom),
      joinedRoom: clearJoined ? null : (joinedRoom ?? this.joinedRoom),
      activeRooms: activeRooms ?? this.activeRooms,
      isLoading: isLoading ?? this.isLoading,
      isWakingServer: isWakingServer ?? this.isWakingServer,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }
}

class RoomController extends StateNotifier<RoomState> {
  RoomController(this._repository) : super(const RoomState());

  final RoomRepository _repository;

  Future<RoomModel?> createRoom({String? name}) async {
    state = state.copyWith(isLoading: true, isWakingServer: true, clearError: true);
    try {
      final room = await _repository.createRoom(name: name);
      state = state.copyWith(
        createdRoom: room,
        isLoading: false,
        isWakingServer: false,
      );
      return room;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isWakingServer: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<RoomModel?> joinRoom(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final room = await _repository.joinRoom(code);
      state = state.copyWith(
        joinedRoom: room,
        isLoading: false,
      );
      return room;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void reset() {
    state = const RoomState();
  }
}

