import 'package:flutter/material.dart';
import 'package:bookjourney_app/Login/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';




Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookJourney',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {


  @override
  Widget build(BuildContext context) {
    return const PopScope(
        canPop: false,
        child:  LoginPage());
  }

}