import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unity_hub/pages/security/auth_page.dart';
import 'package:unity_hub/pages/home_page.dart';
import 'package:github_sign_in_plus/github_sign_in_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GithubSignInButton extends StatefulWidget {
  const GithubSignInButton({super.key});

  @override
  State<GithubSignInButton> createState() => _GithubSignInButtonState();
}

class _GithubSignInButtonState extends State<GithubSignInButton> {
  @override
  Widget build(BuildContext context) {
    void handleSignIn() async {

      final GitHubSignIn gitHubSignIn = GitHubSignIn(
        clientId: dotenv.env['CLIENT_ID_GITHUB_AUTH']!,
        clientSecret: dotenv.env['CLIENT_SECRET_GITHUB_AUTH']!,
        redirectUrl: dotenv.env['GITHUB_REDIRECT_URL']!,
      );

      final result = await gitHubSignIn.signIn(context);
      final token = result.token;

      if (token != null) {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'gh_token', value: token);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }

    }

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

          handleSignIn();

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


