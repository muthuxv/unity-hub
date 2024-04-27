import 'package:flutter/material.dart';
import 'home_page.dart';
import 'security/login_page.dart';
import 'security/register_page.dart';

import '../components/google_sign_in_button.dart';
import '../components/github_sign_in_button.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/images/wall1.png'),
              fit: BoxFit.cover,
            )
          ),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //logo
                  Image.asset(
                    'lib/images/unitylog.png',
                    width: 300,
                    color: Colors.white,

                  ),

                  const SizedBox(height: 16),
                  //title
                  const Text(
                    'Bienvenue sur Unity Hub!',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  //subtitle
                  const SizedBox(height: 16),
                  const Text(
                    'Connecte-toi ou inscris-toi pour accéder à l\'application',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  //button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage(),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(25),
                            child: const Center(
                              child: Text(
                                  'Connexion',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                  )
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage(),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(25),
                            child: const Center(
                              child: Text(
                                  'Inscription',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                  )
                              ),
                            ),
                          ),
                        ),
                        //Oauth2
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Ou connecte-toi avec',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GoogleSignInButton(),
                                    const GithubSignInButton(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ),
            ),
          ),
        ),
      )
    );
  }
}
