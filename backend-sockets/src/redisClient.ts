import { Redis } from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

// Connect to Upstash Redis Free Tier
export const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');

redis.on('connect', () => console.log('✅ Upstash Redis Connected'));
redis.on('error', (err: any) => console.error('❌ Redis Error:', err));

// Room State Typings
export interface RoomState {
  hostId: string;
  currentTrackId: string | null;
  isPlaying: boolean;
  positionMs: number;
  timestamp: number;
}
