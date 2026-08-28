import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:note_app/screen/add_edit_note_screen.dart';
import 'package:note_app/screen/edit_profile.dart';
import 'package:note_app/screen/home_screen.dart';
import 'package:note_app/screen/login_screen.dart';
import 'package:note_app/screen/profile_screen.dart';
import 'package:note_app/screen/signup_page.dart';
import 'package:note_app/screen/splash_screen.dart';
import 'package:note_app/screen/update_password.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/splashscreen",
      routes: {
        "/splashscreen": (context) => SplashScreen(),
        "/login": (context) => LoginScreen(),
        "/signup": (context) => SignUpScreen(),
        "/homepage": (context) => HomeScreen(),
        "/EditProfile": (context) => EditProfile(),
        "/ProfileScreen": (context) => ProfileScreen(),
        "AddEditNoteScreen": (context) => AddEditNoteScreen(),
        "/UpdatePassword": (context) => UpdatePassword(),
      },
      title: 'My Notes',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Color(0xFF1E3A8A),
        scaffoldBackgroundColor: Color(0xFFFAF8F6),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}