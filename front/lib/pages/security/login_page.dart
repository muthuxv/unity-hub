import 'package:flutter/material.dart';
import '../home_page.dart';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  void _login(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog(context, 'Erreur', 'Veuillez remplir tous les champs.');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showErrorDialog(context, 'Erreur', 'Veuillez entrer une adresse email valide.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().post(
        'http://10.0.2.2:8080/login',
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'token', value: response.data['token']);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      } else {
        _showErrorDialog(context, 'Erreur', 'Erreur lors de la connexion. Veuillez réessayer.');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          _showErrorDialog(context, 'Erreur', 'Utilisateur non trouvé.');
        } else if (e.response!.statusCode == 401) {
          _showErrorDialog(context, 'Erreur', 'Mot de passe incorrect.');
        } else {
          _showErrorDialog(context, 'Erreur', 'Erreur lors de la connexion. Veuillez réessayer.');
        }
      } else {
        _showErrorDialog(context, 'Erreur', 'Erreur réseau. Veuillez vérifier votre connexion.');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/wall1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Black container with opacity
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // Content
          SingleChildScrollView(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    //logo
                    Image.asset(
                      'lib/images/unitylog.png',
                      width: 200,
                      height: 200,
                      color: Colors.white,
                    ),
                    //title
                    const Text(
                      'Bon retour parmi nous!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    //subtitle
                    const Text(
                      'Connectez-vous pour continuer',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    //form
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: 'Mot de passe',
                        hintStyle: const TextStyle(color: Colors.white),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        suffixIcon: IconButton(
                          icon: _isObscure
                              ? const Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                          )
                              : const Icon(
                            Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //button
                    GestureDetector(
                      onTap: () => _login(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.all(25),
                          child: _isLoading
                              ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black),
                            ),
                          )
                              : const Center(
                            child: Text(
                              'Se connecter',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //forgot password
                    GestureDetector(
                      onTap: () => print('Forgot password'),
                      child: const Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
