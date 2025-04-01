import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32.0),
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32.0),
                _buildTextField(icon: Icons.person, hint: 'Name'),
                const SizedBox(height: 16.0),
                _buildTextField(
                  icon: Icons.phone,
                  hint: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  icon: Icons.lock,
                  hint: 'Password',
                  isPassword: true,
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  icon: Icons.lock,
                  hint: 'Confirm Password',
                  isPassword: true,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () async {
                    final user = User(
                      uid: "erferfe",
                      nativeLanguage: "english",
                      targetLanguage: "frensh",
                      level: 2,
                      createdAt: DateTime.now(),
                      isPremium: false,
                    );

                    await locator.get<PreferenceRepository>().setUser(
                          jsonEncode(user.toJson()),
                        );

                    context.go("/learn");

                    // Register button doesn't do anything
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
