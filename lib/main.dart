import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_awesome_pims/services/note_api_service.dart';
import 'package:my_awesome_pims/screens/note_list_screen.dart';

// TODO: Change this to your backend IP address on the same WiFi/LAN
const String backendUrl = 'http://192.168.3.19:7777';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = NoteApiService(baseUrl: backendUrl);

    return MaterialApp(
      title: 'My Awesome PIMS',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A73E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          surface: const Color(0xFFFAFAFA),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1A73E8),
        ),
      ),
      home: NoteListScreen(apiService: apiService),
    );
  }
}
