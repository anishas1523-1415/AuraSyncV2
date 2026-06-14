import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/aura_theme.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';

class BlendScreen extends StatefulWidget {
  const BlendScreen({Key? key}) : super(key: key);

  @override
  State<BlendScreen> createState() => _BlendScreenState();
}

class _BlendScreenState extends State<BlendScreen> {
  bool _loading = false;
  Map<String, dynamic>? _blendResult;

  Future<void> _calculateAuraBlend() async {
    setState(() {
      _loading = true;
      _blendResult = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://aurasyncv2.onrender.com/api/blend"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_a": {
            "user_id": "user_alpha",
            "top_genres": {"pop": 0.8, "electronic": 0.6, "chill": 0.9}
          },
          "user_b": {
            "user_id": "user_beta",
            "top_genres": {"pop": 0.7, "electronic": 0.9, "ambient": 0.4}
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _blendResult = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to generate blend: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Blend generation failed: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AuraTheme.getMoodGradient(_blendResult?['blend_vibe'] ?? 'Chill Discovery'),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AURA BLEND",
                  style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Blend your music DNA with friends to see how matching your sound aura is.",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: Center(
                    child: _loading 
                      ? const CircularProgressIndicator(color: AuraTheme.neonCyan)
                      : _blendResult == null 
                        ? _buildInviteCard()
                        : _buildResultCard(),
                  ),
                ),
                const SizedBox(height: 80), // persistent player padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share_arrival_time_rounded, color: AuraTheme.neonPurple, size: 64),
          const SizedBox(height: 24),
          const Text(
            "Sync Sound Aura",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Generate a blend playlist dynamically comparing genre affinity vectors using Cosine Similarity.",
            style: TextStyle(color: Colors.white60, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.flash_on, color: Colors.black),
            label: const TextStyle(fontWeight: FontWeight.bold).buildText("Generate Blend"),
            onPressed: _calculateAuraBlend,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final score = (_blendResult!['similarity_score'] * 100).toInt();
    final vibe = _blendResult!['blend_vibe'];
    final shared = List<String>.from(_blendResult!['shared_genres']);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular compatibility meter
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  color: vibe == 'Energetic Sync' ? AuraTheme.neonPink : AuraTheme.neonCyan,
                ),
              ),
              Text(
                "$score%",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "VIBE: $vibe",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: vibe == 'Energetic Sync' ? AuraTheme.neonPink : AuraTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Shared Affinity Genres",
            style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: shared.map((g) => Chip(
              backgroundColor: Colors.white10,
              label: Text(g.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
            )).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.neonPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayerScreen(moodVibe: vibe)),
              );
            },
            child: const Text("Listen Blended Playlist", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Extension to cleanly chain widgets
extension TextBuild on TextStyle {
  Widget buildText(String data) => Text(data, style: this);
}
