import 'package:bikes/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Bikes',

      theme: ThemeData(

        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,

        pageTransitionsTheme:
        const PageTransitionsTheme(
          builders: {
            TargetPlatform.android:
            NoTransitionsBuilder(),

            TargetPlatform.iOS:
            NoTransitionsBuilder(),
          },
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

class NoTransitionsBuilder
    extends PageTransitionsBuilder {

  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {

    return child;
  }
}