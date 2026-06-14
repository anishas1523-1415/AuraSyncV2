import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/providers/providers.dart';
import '../widgets/glass_container.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  // Streamable Lofi & Synthwave track list (Real YouTube Video IDs)
  static const List<Map<String, String>> tracks = [
    {
      'id': 'jfKfPfyJRdk', // Lofi Girl Synthwave
      'title': 'Lofi Synthwave Session',
      'artist': 'Lofi Girl',
      'art': 'https://picsum.photos/id/10/300/300',
    },
    {
      'id': '5qap5aO4i9A', // Lofi Girl Chill
      'title': 'Chilled Lofi Beats',
      'artist': 'Lofi Girl',
      'art': 'https://picsum.photos/id/20/300/300',
    },
    {
      'id': '4xDzrJKXOOY', // Synthwave Retro
      'title': 'Sunset Drive',
      'artist': 'Retro Synth',
      'art': 'https://picsum.photos/id/30/300/300',
    },
    {
      'id': 'dQw4w9WgXcQ', // Classic Rickroll
      'title': 'Never Gonna Give You Up',
      'artist': 'Rick Astley',
      'art': 'https://picsum.photos/id/40/300/300',
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      body: Container(
        decoration: AuraTheme.getMoodGradient('Chill Discovery'),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Beautiful Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DISCOVER",
                            style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          const CircleAvatar(
                            backgroundImage: NetworkImage("https://picsum.photos/id/64/100/100"),
                            radius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "AI-curated vibes tailored for your current aura.",
                        style: AuraTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: AuraTheme.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Horizontal Slider
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryCard('Cyberpunk', AuraTheme.neonPurple, Icons.bolt),
                      _buildCategoryCard('Chill Lofi', AuraTheme.neonCyan, Icons.spa),
                      _buildCategoryCard('Neon Vibes', AuraTheme.neonPink, Icons.favorite),
                      _buildCategoryCard('Focus Ambient', Colors.amber, Icons.self_improvement),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 24.0, top: 32.0, bottom: 16.0),
                  child: Text(
                    "Hot Stream Proxying",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),

              // Tracks List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(track['art']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              track['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            subtitle: Text(
                              track['artist']!,
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AuraTheme.neonCyan,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                                onPressed: () {
                                  audioHandler.playMediaItem(MediaItem(
                                    id: track['id']!,
                                    album: 'AuraSynq Discovery',
                                    title: track['title']!,
                                    artist: track['artist']!,
                                    artUri: Uri.parse(track['art']!),
                                  ));
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              ),
              
              // Space for bottom player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
