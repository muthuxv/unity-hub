import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:unity_hub/pages/security/auth_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../firebase_options.dart';

class GithubSignInButton extends StatefulWidget {
  const GithubSignInButton({super.key});

  @override
  State<GithubSignInButton> createState() => _GithubSignInButtonState();
}

class _GithubSignInButtonState extends State<GithubSignInButton> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: isLoading ? const CircularProgressIndicator(
        color: Colors.white,
      ) : OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        onPressed: _signInWithGithub,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/images/github_logo.png',
                height: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Continuer avec GitHub',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGithub() async {
    setState(() {
      isLoading = true;
    });
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final OAuthProvider githubProvider = OAuthProvider('github.com');
    githubProvider.addScope('repo');
    githubProvider.addScope('read:user');
    githubProvider.addScope('user:email');

    try {
      final UserCredential userCredential = await _auth.signInWithProvider(githubProvider);
      final User? user = userCredential.user;

      if (user != null) {
        final oauthCredential = userCredential.credential;
        final accessToken = oauthCredential?.accessToken;

        final response = await _dio.get(
          'https://api.github.com/user',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );

        final githubUserData = response.data;
        final githubUsername = githubUserData['login'];
        final githubAvatarUrl = githubUserData['avatar_url'];

        final serverResponse = await _dio.get(
          'http://10.0.2.2:8080/auth/github/callback',
          data: {
            'uid': user.uid,
            'email': user.email,
            'displayName': githubUsername,
            'photoURL': githubAvatarUrl,
          },
        );

        const storage = FlutterSecureStorage();
        await storage.write(key: 'token', value: serverResponse.data['token']);

        setState(() {
          isLoading = false;
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
