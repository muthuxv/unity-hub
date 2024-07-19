import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'profile_pseudo_page.dart';
import 'profile_password_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileAccountPage extends StatefulWidget {
  const ProfileAccountPage({super.key});

  @override
  _ProfileAccountPageState createState() => _ProfileAccountPageState();
}

class _ProfileAccountPageState extends State<ProfileAccountPage> {
  bool _isLoading = true;
  bool _showPasswordButton = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final response = await Dio().get(
        '$apiPath/users/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _showPasswordButton = response.data['Provider'].isEmpty;
        });
      } else {
        _showErrorDialog(response.data['message'] ?? 'Failed to fetch user data');
      }
    } catch (e) {
      _showErrorDialog('Failed to connect to server. Please check your network connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.account,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.accountInformation,
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.username,
                      style: GoogleFonts.nunito(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePseudoPage()),
                      );
                    },
                  ),
                  if (_showPasswordButton)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1),
                    ),
                  if (_showPasswordButton)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.password,
                        style: GoogleFonts.nunito(fontSize: 18),
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePasswordPage()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
