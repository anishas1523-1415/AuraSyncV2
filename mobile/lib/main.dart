import 'package:flutter/material.dart';
import 'core/theme/aura_theme.dart';
import 'ui/screens/player_screen.dart';

void main() {
  runApp(const AuraSynqApp());
}

class AuraSynqApp extends StatelessWidget {
  const AuraSynqApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSynq V2',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.darkTheme,
      home: const PlayerScreen(),
    );
  }
}
