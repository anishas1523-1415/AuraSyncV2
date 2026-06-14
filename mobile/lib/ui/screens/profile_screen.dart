import 'package:flutter/material.dart';
import '../../core/theme/aura_theme.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AuraTheme.getMoodGradient('Chill Discovery'),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MY AURA",
                  style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Sound Aura canvas (Dynamic Neon Gradient visualizer)
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AuraTheme.neonCyan.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AuraTheme.neonPurple.withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: 8,
                        ),
                      ],
                      gradient: const RadialGradient(
                        colors: [
                          AuraTheme.neonCyan,
                          AuraTheme.neonPurple,
                          AuraTheme.neonPink,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "SOUND AURA",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 2.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Affinity stats
                const Text(
                  "Aura Stats",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatTile("Electronic / House", 0.85, AuraTheme.neonCyan),
                _buildStatTile("Cyber Ambient", 0.70, AuraTheme.neonPurple),
                _buildStatTile("Pop / Synth", 0.45, AuraTheme.neonPink),

                const SizedBox(height: 32),

                // Listening History list
                const Text(
                  "Recent Resonance",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildHistoryItem("Cyberpunk Skyline", "Retro Synth", "10m ago"),
                _buildHistoryItem("Lofi Chill Session", "Lofi Girl", "1h ago"),
                _buildHistoryItem("Neon Beats", "DJ Aura", "3h ago"),

                const SizedBox(height: 100), // Persistent player space
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, double value, Color progressColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text("${(value * 100).toInt()}%", style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white10,
                color: progressColor,
                minHeight: 6,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String artist, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(artist, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
            Text(time, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
