import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'core/theme/aura_theme.dart';
import 'core/services/audio_handler.dart';
import 'core/providers/providers.dart';
import 'ui/screens/main_navigation_holder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native background audio service
  final audioHandler = await AudioService.init(
    builder: () => AuraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.aurasynq.v2.channel.audio',
      androidNotificationChannelName: 'AuraSynq Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const AuraSynqApp(),
    ),
  );
}

class AuraSynqApp extends StatelessWidget {
  const AuraSynqApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSynq V2',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.darkTheme,
      home: const MainNavigationHolder(),
    );
  }
}
