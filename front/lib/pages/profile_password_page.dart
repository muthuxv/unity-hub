import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'profile_page.dart';

class ProfilePasswordPage extends StatefulWidget {
  const ProfilePasswordPage({Key? key}) : super(key: key);

  @override
  _ProfilePasswordPageState createState() => _ProfilePasswordPageState();
}

class _ProfilePasswordPageState extends State<ProfilePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
      final userId = decodedToken['jti'];

      final response = await Dio().put(
        'http://10.0.2.2:8080/users/$userId/change-password',
        data: {
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Succès'),
            content: Text('Votre mot de passe a été changé avec succès.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  Navigator.of(context).pop(true);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog('Erreur lors de la mise à jour du mot de passe');
      }
    } catch (e) {
      _showErrorDialog('Erreur de connexion: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Changer le Mot de Passe', style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: "Mot de passe actuel",
                  hintText: "Entrez votre mot de passe actuel",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Le mot de passe ne peut pas être vide" : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  hintText: "Entrez votre nouveau mot de passe",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
                obscureText: true,
                validator: (value) => value!.isEmpty || value.length < 6 ? "Le nouveau mot de passe doit avoir au moins 6 caractères" : null,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: Text('Changer le mot de passe', style: GoogleFonts.nunito(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
