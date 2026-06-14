import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/aura_theme.dart';
import '../../core/providers/providers.dart';
import '../widgets/glass_container.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String moodVibe;

  const PlayerScreen({Key? key, this.moodVibe = 'Chill Discovery'}) : super(key: key);

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showLyrics = false;
  List<LrcLine> _lyrics = [];
  bool _loadingLyrics = false;
  String? _loadedLyricsTrackId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics(String title, String artist, String trackId) async {
    if (_loadedLyricsTrackId == trackId) return;
    setState(() {
      _loadingLyrics = true;
      _lyrics = [];
    });

    try {
      final cleanTitle = Uri.encodeComponent(title);
      final cleanArtist = Uri.encodeComponent(artist);
      final response = await http.get(
        Uri.parse("https://aurasyncv2.onrender.com/api/lyrics?track_name=$cleanTitle&artist_name=$cleanArtist"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final syncedLrc = data['synced_lyrics'] as String?;
        if (syncedLrc != null) {
          setState(() {
            _lyrics = _parseLrc(syncedLrc);
            _loadedLyricsTrackId = trackId;
          });
        }
      }
    } catch (e) {
      print("Failed to fetch synced lyrics: $e");
    } finally {
      setState(() {
        _loadingLyrics = false;
      });
    }
  }

  List<LrcLine> _parseLrc(String lrcContent) {
    final List<LrcLine> parsed = [];
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    for (var line in lrcContent.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        final duration = Duration(minutes: min, seconds: sec, milliseconds: ms * 10);
        parsed.add(LrcLine(duration, text));
      }
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) {
          return const Scaffold(
            body: Center(
              child: Text("No track selected", style: TextStyle(color: Colors.white60)),
            ),
          );
        }

        // Fetch lyrics on track change
        if (_showLyrics) {
          _fetchLyrics(mediaItem.title, mediaItem.artist ?? '', mediaItem.id);
        }

        return StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, stateSnapshot) {
            final playbackState = stateSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;
            final position = playbackState?.position ?? Duration.zero;
            final duration = mediaItem.duration ?? Duration.zero;

            return Scaffold(
              body: Container(
                decoration: AuraTheme.getMoodGradient(widget.moodVibe),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              "NOW RESONATING",
                              style: AuraTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                                color: AuraTheme.neonCyan,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showLyrics ? Icons.music_note_rounded : Icons.lyrics_rounded, 
                                color: _showLyrics ? AuraTheme.neonPink : Colors.white, 
                                size: 28
                              ),
                              onPressed: () {
                                setState(() {
                                  _showLyrics = !_showLyrics;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Dynamic View (Album Art vs Synced Lyrics)
                      Expanded(
                        child: Center(
                          child: _showLyrics 
                            ? _buildLyricsView(position)
                            : _buildAlbumArtView(mediaItem.artUri?.toString()),
                        ),
                      ),

                      // Info and Playback Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        child: Column(
                          children: [
                            Text(
                              mediaItem.title,
                              style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mediaItem.artist ?? 'Unknown Artist',
                              style: AuraTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AuraTheme.neonPink, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Interactive Progress Slider Bar
                            _buildProgressSlider(position, duration, audioHandler),

                            const SizedBox(height: 24),

                            // Control Dial
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              borderRadius: BorderRadius.circular(40),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                                    onPressed: () => audioHandler.skipToPrevious(),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (isPlaying) {
                                        audioHandler.pause();
                                      } else {
                                        audioHandler.play();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                        color: AuraTheme.backgroundDark, 
                                        size: 36
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                                    onPressed: () => audioHandler.skipToNext(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumArtView(String? artUrl) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AuraTheme.neonPurple.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(artUrl ?? "https://picsum.photos/500"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLyricsView(Duration position) {
    if (_loadingLyrics) {
      return const CircularProgressIndicator(color: AuraTheme.neonCyan);
    }
    if (_lyrics.isEmpty) {
      return const Text("Synced lyrics unavailable for this resonance", style: TextStyle(color: Colors.white38));
    }

    // Find active lyric line index
    int activeIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (position >= _lyrics[i].timestamp) {
        activeIndex = i;
      }
    }

    return ListWheelScrollView.useDelegate(
      itemExtent: 50,
      perspective: 0.003,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      controller: FixedExtentScrollController(initialItem: activeIndex >= 0 ? activeIndex : 0),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          final isHighlighted = index == activeIndex;
          return Center(
            child: Text(
              _lyrics[index].text,
              style: TextStyle(
                color: isHighlighted ? AuraTheme.neonCyan : Colors.white24,
                fontSize: isHighlighted ? 20 : 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
        childCount: _lyrics.length,
      ),
    );
  }

  Widget _buildProgressSlider(Duration position, Duration duration, AudioHandler audioHandler) {
    final posMs = position.inMilliseconds.toDouble();
    final durMs = duration.inMilliseconds.toDouble();
    final value = durMs > 0 ? posMs.clamp(0.0, durMs) : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AuraTheme.neonCyan,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            overlayColor: AuraTheme.neonCyan.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            max: durMs > 0 ? durMs : 1.0,
            onChanged: (val) {
              audioHandler.seek(Duration(milliseconds: val.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}

class LrcLine {
  final Duration timestamp;
  final String text;
  LrcLine(this.timestamp, this.text);
}
