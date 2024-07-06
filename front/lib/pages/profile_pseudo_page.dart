import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePseudoPage extends StatefulWidget {
  const ProfilePseudoPage({super.key});

  @override
  _ProfilePseudoPageState createState() => _ProfilePseudoPageState();
}

class _ProfilePseudoPageState extends State<ProfilePseudoPage> {
  final TextEditingController _pseudoController = TextEditingController();
  String _originalPseudo = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPseudo();
  }

  Future<void> _loadPseudo() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
      final userId = decodedToken['jti'];

      final response = await Dio().get(
        'http://10.0.2.2:8080/users/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pseudoController.text = response.data['Pseudo'];
          _originalPseudo = response.data['Pseudo'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du pseudo: $e');
    }
  }

  Future<void> _updatePseudo() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().put(
      'http://10.0.2.2:8080/users/$userId',
      data: {
        'Pseudo': _pseudoController.text,
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
          title: Text(AppLocalizations.of(context)!.pseudoUpdated),
          content: Text(AppLocalizations.of(context)!.pseudoUpdatedSuccess),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog(AppLocalizations.of(context)!.errorUpdatingPseudo);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.modifyPseudo,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _pseudoController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.pseudo,
                hintText: AppLocalizations.of(context)!.enterNewPseudo,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger UI rebuild
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _pseudoController.text != _originalPseudo && _pseudoController.text.isNotEmpty
                    ? _updatePseudo
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}