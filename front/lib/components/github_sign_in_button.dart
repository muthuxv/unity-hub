import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unity_hub/pages/intro_page.dart';
import 'package:unity_hub/pages/security/auth_page.dart';
import 'package:unity_hub/pages/home_page.dart';
import 'package:github_sign_in_plus/github_sign_in_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class GithubSignInButton extends StatefulWidget {
  const GithubSignInButton({super.key});

  @override
  State<GithubSignInButton> createState() => _GithubSignInButtonState();
}

class _GithubSignInButtonState extends State<GithubSignInButton> {
  /*
  void handleSignIn() async {
    if (!mounted) return; // Check if the widget is still mounted

    final GitHubSignIn gitHubSignIn = GitHubSignIn(
      clientId: dotenv.env['CLIENT_ID_GITHUB_AUTH']!,
      clientSecret: dotenv.env['CLIENT_SECRET_GITHUB_AUTH']!,
      redirectUrl: dotenv.env['GITHUB_REDIRECT_URL']!,
    );

    final result = await gitHubSignIn.signIn(context);
    final accessToken = result.token;

    if (!mounted) {
      print(context);
      print('mounted');
      return;
    }

    switch (result.status) {
      case GitHubSignInResultStatus.ok:
        final dio = Dio();
        final response = await dio.get(
          'http://195.35.29.110:8080/auth/github/callback?token=$accessToken',
        );
        print(response.data);
        print(context);
        break;
      case GitHubSignInResultStatus.cancelled:
        print('Sign in cancelled by user');
        break;
      case GitHubSignInResultStatus.failed:
        print('Sign in failed');
        break;
      default:
        print('Sign in failed');
        break;
    }
  }

   */

  Future<void> handleSignIn(BuildContext context) async {
    final GitHubSignIn gitHubSignIn = GitHubSignIn(
      clientId: dotenv.env['CLIENT_ID_GITHUB_AUTH']!,
      clientSecret: dotenv.env['CLIENT_SECRET_GITHUB_AUTH']!,
      redirectUrl: dotenv.env['GITHUB_REDIRECT_URL']!,
    );

    final result = await gitHubSignIn.signIn(context);
    final accessToken = result.token;

    print('GitHub accesstoken: $accessToken');

    try {
      final result = await gitHubSignIn.signIn(context);

      if (result.status == GitHubSignInResultStatus.ok) {
        print('GitHub token: $accessToken');
      } else {
        // Handle sign-in failure
        print('GitHub sign-in failed: ${result.errorMessage}');
      }
    } catch (error) {
      // Handle any errors that occur during sign-in process
      print('Error signing in with GitHub: $error');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        onPressed: () async {
          handleSignIn(context);
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage("lib/images/github_logo.png"),
              height: 35.0,
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Github',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}



