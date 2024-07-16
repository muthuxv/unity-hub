import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

import '../pages/security/auth_page.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;
  final _dio = Dio();

  @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _isSigningIn ? const CircularProgressIndicator() : OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          onPressed: () async {
            setState(() {
              _isSigningIn = true;
            });

            try {
              final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
              if (googleUser == null) {
                setState(() {
                  _isSigningIn = false;
                });
                return;
              }
              final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
              final OAuthCredential credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              await FirebaseAuth.instance.signInWithCredential(credential);

              await _dio.get(
                '${dotenv.env['API_PATH']}/auth/google/callback',
                data: {
                  'uid': FirebaseAuth.instance.currentUser!.uid,
                  'email': FirebaseAuth.instance.currentUser!.email,
                  'displayName': FirebaseAuth.instance.currentUser!.displayName,
                  'photoURL': FirebaseAuth.instance.currentUser!.photoURL,
                },
              ).then((response) {
                if (response.statusCode == 200) {
                  const storage = FlutterSecureStorage();
                  storage.write(key: 'token', value: response.data['token']);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthPage()
                    ),
                  );

                } else {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Erreur'),
                        content: Text(response.data['message']),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              });
            } catch (e) {
              const SnackBar(
                content: Text('Erreur de connexion'),
              );
            }

            setState(() {
              _isSigningIn = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/images/google_logo.png',
                  height: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Continuer avec Google',
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
  }