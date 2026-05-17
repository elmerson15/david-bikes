import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {

    super.initState();

    Timer(

      const Duration(seconds: 2),

          () {

        if (FirebaseAuth
            .instance
            .currentUser != null) {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>

              const DashboardScreen(),
            ),
          );

        } else {

          Navigator.pushReplacement(

            context,

            MaterialPageRoute(

              builder: (_) =>

              const LoginScreen(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      Colors.black,

      body: Center(

        child: Image.asset(

          "assets/splash.jpg",

          fit: BoxFit.contain,

          width:
          MediaQuery.of(context)
              .size
              .width,

          height:
          MediaQuery.of(context)
              .size
              .height,
        ),
      ),
    );
  }
}