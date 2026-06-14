import express from 'express';
import http from 'http';
import { Server, Socket } from 'socket.io';
import cors from 'cors';
import { redis, type RoomState } from './redisClient.js';

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // Lock this down to the Flutter Web/App domains in production
    methods: ['GET', 'POST']
  }
});

// Helper to update and broadcast room state from Redis
async function syncRoomState(roomId: string) {
  const stateStr = await redis.get(`room:${roomId}`);
  if (stateStr) {
    io.to(roomId).emit('sync_state', JSON.parse(stateStr));
  }
}

io.on('connection', (socket: Socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  // 1. Join a Society Room
  socket.on('join_room', async ({ roomId, userId, isHost }) => {
    socket.join(roomId);
    
    // Initialize room in Redis if host
    if (isHost) {
      const initialState: RoomState = {
        hostId: userId,
        currentTrackId: null,
        isPlaying: false,
        positionMs: 0,
        timestamp: Date.now()
      };
      await redis.set(`room:${roomId}`, JSON.stringify(initialState));
    }
    
    // Send immediate state to joining user
    const stateStr = await redis.get(`room:${roomId}`);
    if (stateStr) {
      socket.emit('sync_state', JSON.parse(stateStr));
    }
    
    socket.to(roomId).emit('user_joined', { userId });
  });

  // 2. Host Playback Controls (Strict Authority)
  socket.on('host_action', async ({ roomId, action, payload }) => {
    const stateStr = await redis.get(`room:${roomId}`);
    if (!stateStr) return;

    const state: RoomState = JSON.parse(stateStr);
    
    // Update state based on host action
    if (action === 'play') state.isPlaying = true;
    if (action === 'pause') state.isPlaying = false;
    if (action === 'seek') state.positionMs = payload.positionMs;
    if (action === 'change_track') {
      state.currentTrackId = payload.trackId;
      state.positionMs = 0;
      state.isPlaying = true;
    }
    
    state.timestamp = Date.now(); // Used by clients to calculate drift latency

    // Save to Redis and broadcast instantly
    await redis.set(`room:${roomId}`, JSON.stringify(state));
    await syncRoomState(roomId);
  });

  // 3. Real-time Chat
  socket.on('send_message', ({ roomId, userId, message }) => {
    io.to(roomId).emit('receive_message', { userId, message, timestamp: Date.now() });
  });

  // 4. Vibe Reactions (Floating Neon Bubbles)
  socket.on('send_reaction', ({ roomId, userId, reactionType }) => {
    // reactionType e.g., 'fire', 'heart', 'chill'
    io.to(roomId).emit('receive_reaction', { userId, reactionType });
  });

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 Live Society Socket Server running on port ${PORT}`);
});
