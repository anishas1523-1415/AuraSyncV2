import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../services/audio_handler.dart';
import '../network/socket_client.dart';

// Provider for global audio handler
final audioHandlerProvider = Provider<AudioHandler>((ref) {
  throw UnimplementedError('Initialize audioHandler in main() first');
});

// Provider for Socket Client
final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient();
  ref.onDispose(() {
    client.disconnect();
  });
  return client;
});

// Room State model for collaborative playback
class RoomStateData {
  final String roomId;
  final String hostId;
  final String? currentTrackId;
  final bool isPlaying;
  final int positionMs;
  final List<String> activeUsers;

  RoomStateData({
    required this.roomId,
    required this.hostId,
    this.currentTrackId,
    this.isPlaying = false,
    this.positionMs = 0,
    this.activeUsers = const [],
  });

  RoomStateData copyWith({
    String? roomId,
    String? hostId,
    String? currentTrackId,
    bool? isPlaying,
    int? positionMs,
    List<String>? activeUsers,
  }) {
    return RoomStateData(
      roomId: roomId ?? this.roomId,
      hostId: hostId ?? this.hostId,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      isPlaying: isPlaying ?? this.isPlaying,
      positionMs: positionMs ?? this.positionMs,
      activeUsers: activeUsers ?? this.activeUsers,
    );
  }
}

// StateNotifier to sync Socket.io server state to UI
class RoomStateNotifier extends StateNotifier<RoomStateData?> {
  final SocketClient _socketClient;

  RoomStateNotifier(this._socketClient) : super(null);

  void joinRoom(String roomId, String userId, bool isHost) {
    state = RoomStateData(roomId: roomId, hostId: isHost ? userId : '');
    _socketClient.connect(userId);
    _socketClient.joinRoom(roomId, userId, isHost);

    _socketClient.listenToRoomState((data) {
      state = RoomStateData(
        roomId: roomId,
        hostId: data['hostId'] ?? '',
        currentTrackId: data['currentTrackId'],
        isPlaying: data['isPlaying'] ?? false,
        positionMs: data['positionMs'] ?? 0,
        activeUsers: List<String>.from(data['activeUsers'] ?? []),
      );
    });
  }

  void leaveRoom() {
    _socketClient.disconnect();
    state = null;
  }
}

final roomStateProvider = StateNotifierProvider<RoomStateNotifier, RoomStateData?>((ref) {
  final socketClient = ref.watch(socketClientProvider);
  return RoomStateNotifier(socketClient);
});
