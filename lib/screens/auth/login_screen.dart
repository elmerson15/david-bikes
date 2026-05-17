import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  bool isLoading = false;

  Future<void> login() async {

    try {

      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(

        email:
        emailController.text.trim(),

        password:
        passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const DashboardScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            e.message ??
                "Login Failed",
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,

            colors: [

              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          ),
        ),

        child: SafeArea(

          child: Center(

            child: SingleChildScrollView(

              padding:
              const EdgeInsets.all(25),

              child: Container(

                padding:
                const EdgeInsets.all(25),

                decoration: BoxDecoration(

                  color:
                  Colors.white.withOpacity(0.08),

                  borderRadius:
                  BorderRadius.circular(25),

                  border: Border.all(
                    color:
                    Colors.white24,
                  ),
                ),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.motorcycle,
                      size: 80,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 20),

                    const Text(

                      "DAVID'S BIKES",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(

                      "Admin Login",

                      style: TextStyle(
                        color:
                        Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 40),

                    TextField(

                      controller:
                      emailController,

                      style: const TextStyle(
                        color:
                        Colors.white,
                      ),

                      decoration:
                      InputDecoration(

                        hintText:
                        "Email",

                        hintStyle:
                        const TextStyle(
                          color:
                          Colors.white54,
                        ),

                        prefixIcon:
                        const Icon(
                          Icons.email,
                          color:
                          Colors.white,
                        ),

                        filled: true,

                        fillColor:
                        Colors.white10,

                        border:
                        OutlineInputBorder(

                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(

                      controller:
                      passwordController,

                      obscureText: true,

                      style: const TextStyle(
                        color:
                        Colors.white,
                      ),

                      decoration:
                      InputDecoration(

                        hintText:
                        "Password",

                        hintStyle:
                        const TextStyle(
                          color:
                          Colors.white54,
                        ),

                        prefixIcon:
                        const Icon(
                          Icons.lock,
                          color:
                          Colors.white,
                        ),

                        filled: true,

                        fillColor:
                        Colors.white10,

                        border:
                        OutlineInputBorder(

                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    SizedBox(

                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(

                        style:
                        ElevatedButton.styleFrom(

                          backgroundColor:
                          Colors.white,

                          foregroundColor:
                          Colors.black,

                          shape:
                          RoundedRectangleBorder(

                            borderRadius:
                            BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),

                        onPressed:
                        isLoading
                            ? null
                            : login,

                        child: isLoading

                            ? const CircularProgressIndicator()

                            : const Text(

                          "LOGIN",

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}