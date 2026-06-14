import 'package:flutter/material.dart';
import '../../core/theme/aura_theme.dart';
import '../widgets/glass_container.dart';

class PlayerScreen extends StatefulWidget {
  final String moodVibe;

  const PlayerScreen({Key? key, this.moodVibe = 'Energetic Sync'}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // 60fps locked hardware animation for the neon glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                    Text(
                      "LIVE SOCIETY",
                      style: AuraTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: AuraTheme.neonCyan,
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: Colors.white, size: 32),
                  ],
                ),
              ),

              // Album Art (Animated Physics Bubble)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AuraTheme.neonPurple.withOpacity(0.4),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                        image: const DecorationImage(
                          image: NetworkImage("https://picsum.photos/500"), // Placeholder track art
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Track Info & Floating Action Dial
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  children: [
                    Text(
                      "Cyberpunk Skyline",
                      style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "AuraSynq AI Blend",
                      style: AuraTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AuraTheme.neonPink),
                    ),
                    const SizedBox(height: 40),
                    
                    // Glassmorphism Floating Control Dial
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      borderRadius: BorderRadius.circular(40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.pause_rounded, color: AuraTheme.backgroundDark, size: 36),
                          ),
                          const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
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
  }
}
