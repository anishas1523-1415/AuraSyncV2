import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/theme/aura_theme.dart';
import '../../core/providers/providers.dart';
import '../widgets/glass_container.dart';

class SocietyScreen extends ConsumerStatefulWidget {
  const SocietyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends ConsumerState<SocietyScreen> with TickerProviderStateMixin {
  final TextEditingController _roomController = TextEditingController(text: 'SOCIETY-7');
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<FloatingReaction> _reactions = [];
  late AnimationController _reactionLoopController;
  final String _currentUserId = 'user_${math.Random().nextInt(1000)}';

  @override
  void initState() {
    super.initState();
    _reactionLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          // Update bubble positions
          for (var i = _reactions.length - 1; i >= 0; i--) {
            final bubble = _reactions[i];
            bubble.y -= bubble.speedY;
            bubble.x += math.sin(bubble.angle) * 1.5;
            bubble.angle += 0.05;
            bubble.opacity -= 0.015;

            if (bubble.opacity <= 0) {
              _reactions.removeAt(i);
            }
          }
        });
      })..repeat();
  }

  @override
  void dispose() {
    _roomController.dispose();
    _chatController.dispose();
    _reactionLoopController.dispose();
    super.dispose();
  }

  void _triggerReaction(String reactionType) {
    final client = ref.read(socketClientProvider);
    final roomState = ref.read(roomStateProvider);
    if (roomState != null) {
      client.socket.emit('send_reaction', {
        'roomId': roomState.roomId,
        'userId': _currentUserId,
        'reactionType': reactionType,
      });
      _addLocalReaction(reactionType);
    }
  }

  void _addLocalReaction(String type) {
    final rand = math.Random();
    Color color;
    switch (type) {
      case 'fire': color = AuraTheme.neonPink; break;
      case 'heart': color = Colors.red; break;
      case 'chill': color = AuraTheme.neonCyan; break;
      default: color = AuraTheme.neonPurple;
    }
    setState(() {
      _reactions.add(
        FloatingReaction(
          x: rand.nextDouble() * 200 + 50,
          y: 350.0,
          speedY: rand.nextDouble() * 3 + 2,
          color: color,
          type: type,
        ),
      );
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final roomState = ref.read(roomStateProvider);
    if (roomState != null) {
      ref.read(socketClientProvider).socket.emit('send_message', {
        'roomId': roomState.roomId,
        'userId': _currentUserId,
        'message': text,
      });
      setState(() {
        _messages.add({'user': 'You', 'text': text});
      });
    }
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomStateProvider);
    final socketClient = ref.watch(socketClientProvider);

    // Setup socket listeners once connected
    if (roomState != null) {
      socketClient.socket.off('receive_message');
      socketClient.socket.on('receive_message', (data) {
        if (data['userId'] != _currentUserId) {
          if (mounted) {
            setState(() {
              _messages.add({
                'user': (data['userId'] as String).substring(0, 7),
                'text': data['message'] as String,
              });
            });
          }
        }
      });

      socketClient.socket.off('receive_reaction');
      socketClient.socket.on('receive_reaction', (data) {
        if (data['userId'] != _currentUserId) {
          if (mounted) {
            _addLocalReaction(data['reactionType'] as String);
          }
        }
      });
    }

    return Scaffold(
      body: Container(
        decoration: AuraTheme.getMoodGradient(roomState != null ? 'Energetic Sync' : 'Chill Discovery'),
        child: SafeArea(
          child: roomState == null 
            ? _buildJoinView() 
            : _buildRoomView(roomState),
        ),
      ),
    );
  }

  Widget _buildJoinView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LIVE SOCIETY",
            style: AuraTheme.darkTheme.textTheme.displayLarge?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Join collaborative rooms. Listen in real-time sync with friends using distributed Upstash Redis state locks.",
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 40),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                TextField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: "Society Room Code",
                    labelStyle: const TextStyle(color: AuraTheme.neonCyan),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AuraTheme.neonCyan),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuraTheme.neonPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(roomStateProvider.notifier).joinRoom(
                            _roomController.text, 
                            _currentUserId, 
                            true
                          );
                        },
                        child: const Text("Create as Host", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AuraTheme.neonCyan,
                          side: const BorderSide(color: AuraTheme.neonCyan),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(roomStateProvider.notifier).joinRoom(
                            _roomController.text, 
                            _currentUserId, 
                            false
                          );
                        },
                        child: const Text("Join Lobby", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomView(RoomStateData roomState) {
    final isHost = roomState.hostId == _currentUserId;

    return Stack(
      children: [
        // Real-time floating custom physics bubbles (rendered on state updates)
        Positioned.fill(
          child: CustomPaint(
            painter: ReactionPainter(_reactions),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Control Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ROOM: ${roomState.roomId}",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHost ? "👑 You are the Host" : "🎧 Synchronized to Host",
                        style: TextStyle(color: isHost ? AuraTheme.neonPink : AuraTheme.neonCyan, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 28),
                    onPressed: () {
                      ref.read(roomStateProvider.notifier).leaveRoom();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Users Panel
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: AuraTheme.neonCyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${roomState.activeUsers.length + 1} users connected vibe-sharing",
                      style: const TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chat log viewport
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          reverse: false,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: RichText(
                                text: TextSpan(
                                  text: "${msg['user']}: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: msg['user'] == 'You' ? AuraTheme.neonCyan : AuraTheme.neonPurple
                                  ),
                                  children: [
                                    TextSpan(
                                      text: msg['text'],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal)
                                    )
                                  ]
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Send message to room...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.white30),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AuraTheme.neonCyan),
                            onPressed: _sendMessage,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vibe Reaction Panel (Floating Neon Bubbles Dial)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReactionBtn('🔥', 'fire'),
                  _buildReactionBtn('❤️', 'heart'),
                  _buildReactionBtn('✨', 'chill'),
                ],
              ),
              const SizedBox(height: 80), // bottom player spacing
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBtn(String emoji, String type) {
    return InkWell(
      onTap: () => _triggerReaction(type),
      borderRadius: BorderRadius.circular(30),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.circular(30),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class FloatingReaction {
  double x;
  double y;
  double speedY;
  double angle = math.Random().nextDouble() * 2 * math.pi;
  double opacity = 1.0;
  final Color color;
  final String type;

  FloatingReaction({
    required this.x,
    required this.y,
    required this.speedY,
    required this.color,
    required this.type,
  });
}

class ReactionPainter extends CustomPainter {
  final List<FloatingReaction> reactions;

  ReactionPainter(this.reactions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var bubble in reactions) {
      paint.color = bubble.color.withOpacity(bubble.opacity);
      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        12.0,
        paint,
      );
      // Optional: Add glow blur
      final glowPaint = Paint()
        ..color = bubble.color.withOpacity(bubble.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        22.0,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
