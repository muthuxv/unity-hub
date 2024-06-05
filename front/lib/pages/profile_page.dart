import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'friend_page.dart';
import 'update_profile_page.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _pseudo = 'Pseudo Utilisateur';
  String _email = 'pseudo@exemple.com';

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
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pseudo = response.data['Pseudo'];
          _email = response.data['Email'];
          _isLoading = false;
        });
      } else {
        print('Erreur lors de la récupération des données utilisateur');
      }
    } catch (e) {
      print('Erreur de connexion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profil', style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple[300],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
              if (result == true) {
                _loadUserData();  // Rechargez les données utilisateur si la page de mise à jour renvoie true
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProfileSection(context),
            _buildButtons(context),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.deepPurple[50],
            child: CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage('assets/avatar.jpg'), // Assurez-vous que cette image est disponible
            ),
          ),
          SizedBox(height: 10),
          Text(_pseudo, style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(_email, style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("À propos de moi",
                  style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              SizedBox(height: 10),
              Text(
                "Bienvenue sur votre profil ! Modifiez vos informations ou consultez vos amis.",
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
              );
              if (result == true) {
                _loadUserData();  // Rechargez les données utilisateur si la page de mise à jour renvoie true
              }
            },
            child: Text('Modifier le profil', style: GoogleFonts.nunito(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: Size(double.infinity, 56),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendPage()),
              );
            },
            icon: Icon(Icons.people, size: 28),
            label: Text('Mes amis', style: GoogleFonts.nunito(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }
}