import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:random_avatar/random_avatar.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String _pseudo = '';
  String _originalPseudo = '';
  String _mail = '';
  String _avatar = '';
  bool _isLoading = true;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
      final userId = decodedToken['jti'];

      final response = await Dio().get(
        'http://10.0.2.2:8080/users/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pseudo = response.data['Pseudo'];
          _mail = response.data['Email'];
          _originalPseudo = response.data['Pseudo'];
          _avatar = response.data['Profile'] ?? '';
          _isLoading = false;
          _isButtonEnabled = false;
        });
      } else {
        _showErrorDialog(AppLocalizations.of(context)!.errorFetchingUserData);
      }
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.connectionError);
    }
  }

  Future<void> _updateProfile() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().put(
      'http://10.0.2.2:8080/users/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
      data: {
        'Pseudo': _pseudo,
      },
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.profileUpdated),
          content: Text(AppLocalizations.of(context)!.pseudoUpdatedSuccessfully),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog(AppLocalizations.of(context)!.errorUpdatingProfile);
    }
  }

  Future<void> _updateProfilePicture() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken['jti'];

    final response = await Dio().put(
      'http://10.0.2.2:8080/users/$userId',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
      data: {
        'Profile': _avatar,
      },
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profilePictureUpdated),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _showErrorDialog(AppLocalizations.of(context)!.errorUpdatingProfile);
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

  void _generateRandomAvatar() {
    setState(() {
      _avatar = RandomAvatarString(DateTime.now().millisecondsSinceEpoch.toString());
    });
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: Text(AppLocalizations.of(context)!.generateNewAvatar),
              onTap: () {
                _generateRandomAvatar();
                _updateProfilePicture();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.modifyProfile,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[300],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.pseudo,
                        hintText: AppLocalizations.of(context)!.enterNewPseudo,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      initialValue: _pseudo,
                      onChanged: (value) {
                        setState(() {
                          _pseudo = value;
                          _isButtonEnabled = _pseudo != _originalPseudo;
                        });
                      },
                      validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.pseudoCannotBeEmpty : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isButtonEnabled ? () {
                        if (_formKey.currentState!.validate()) {
                          _updateProfile();
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(AppLocalizations.of(context)!.update, style: GoogleFonts.nunito(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.deepPurple[300],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple[50],
                  child: _avatar.contains('<svg')
                      ? SvgPicture.string(
                    _avatar,
                    height: 120,
                    width: 120,
                  )
                      : CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_avatar),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: _changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(width: 2, color: Colors.deepPurple[300]!),
                    ),
                    child: Icon(Icons.edit, color: Colors.deepPurple[300], size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _pseudo,
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            _mail,
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}