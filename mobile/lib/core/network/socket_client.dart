import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketClient {
  late IO.Socket socket;
  final String serverUrl = "https://your-node-backend.onrender.com";

  void connect(String userId) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('🔌 Connected to Live Society Server');
    });

    socket.onDisconnect((_) {
      debugPrint('❌ Disconnected from Live Society Server');
    });
  }

  // Join a collaborative room
  void joinRoom(String roomId, String userId, bool isHost) {
    socket.emit('join_room', {
      'roomId': roomId,
      'userId': userId,
      'isHost': isHost,
    });
  }

  // Listen for strict state syncs from the host/Redis
  void listenToRoomState(Function(Map<String, dynamic>) onStateSync) {
    socket.on('sync_state', (data) {
      onStateSync(data);
    });
  }

  // Broadcast playback actions (Host only)
  void emitHostAction(String roomId, String action, Map<String, dynamic> payload) {
    socket.emit('host_action', {
      'roomId': roomId,
      'action': action,
      'payload': payload,
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
