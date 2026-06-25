import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/neko_app.dart';
import 'firebase_options.dart';
import 'theme/neko_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load. Using defaults.");
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFF8F0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NekoMain());
}

class NekoMain extends StatelessWidget {
  const NekoMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neko',
      debugShowCheckedModeBanner: false,
      theme: NekoTheme.light,
      home: const NekoApp(),
    );
  }
}
