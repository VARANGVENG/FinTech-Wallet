import 'package:fintech_wallet/app/main_navigation.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/login_page.dart';
import 'package:fintech_wallet/features/dashboard/presentation/page/home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}
