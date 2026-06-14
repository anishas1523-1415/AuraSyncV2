import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/providers/providers.dart';
import '../widgets/glass_container.dart';
import 'discover_screen.dart';
import 'society_screen.dart';
import 'blend_screen.dart';
import 'profile_screen.dart';
import 'player_screen.dart';

class MainNavigationHolder extends ConsumerStatefulWidget {
  const MainNavigationHolder({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends ConsumerState<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    SocietyScreen(),
    BlendScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Current page
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Persistent Mini Player & Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Mini Player Stream Builder
                StreamBuilder<MediaItem?>(
                  stream: audioHandler.mediaItem,
                  builder: (context, mediaSnapshot) {
                    final mediaItem = mediaSnapshot.data;
                    if (mediaItem == null) return const SizedBox.shrink();

                    return StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, stateSnapshot) {
                        final playbackState = stateSnapshot.data;
                        final isPlaying = playbackState?.playing ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(
                                    moodVibe: _currentIndex == 1 ? 'Energetic Sync' : 'Chill Discovery',
                                  ),
                                ),
                              );
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.all(8),
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  // Album art
                                  if (mediaItem.artUri != null)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(mediaItem.artUri!.toString()),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  // Title & Artist
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mediaItem.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mediaItem.artist ?? 'Unknown Artist',
                                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Play/Pause button
                                  IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        audioHandler.pause();
                                      } else {
                                        audioHandler.play();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // 2. Custom Neon Bottom Navigation Bar
                Container(
                  color: AuraTheme.backgroundDark.withOpacity(0.95),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.explore, "Discover"),
                        _buildNavItem(1, Icons.radio, "Society"),
                        _buildNavItem(2, Icons.track_changes, "Blend"),
                        _buildNavItem(3, Icons.person, "Profile"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = index == 0 
        ? AuraTheme.neonCyan 
        : index == 1 
            ? AuraTheme.neonPurple 
            : index == 2 
                ? AuraTheme.neonPink 
                : Colors.white;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : Colors.white38,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.white38,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
