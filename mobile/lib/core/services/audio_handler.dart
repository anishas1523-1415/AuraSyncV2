import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class AuraAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final String proxyBaseUrl = "https://aurasyncv2.onrender.com/api/stream/";

  AuraAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Broadcast playback state to the lock screen and UI
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    // V2 MANDATE: Silent Fallback Logic for Stream Failures
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('AuraSynq Audio Error: $e');
      // DO NOT show popup alerts. Silently skip to the next track.
      skipToNext();
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    mediaItemValue.add(mediaItem);
    
    try {
      // Use the Stealth Python Proxy to extract the URL safely
      final streamUrl = "$proxyBaseUrl${mediaItem.id}";
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      await _player.play();
    } catch (e) {
      print("Stream Extraction Failed: $e");
      skipToNext(); // Silent failure
    }
  }
}
