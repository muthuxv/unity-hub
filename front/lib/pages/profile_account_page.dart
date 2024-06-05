import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_pseudo_page.dart';  // Assurez-vous d'importer la page pseudo
import 'profile_password_page.dart';  // Assurez-vous d'importer la page mot de passe

class ProfileAccountPage extends StatelessWidget {
  const ProfileAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compte', style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Information du compte", style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    title: Text("Pseudo", style: GoogleFonts.nunito(fontSize: 18)),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePseudoPage()),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1),
                  ),
                  ListTile(
                    title: Text("Mot de passe", style: GoogleFonts.nunito(fontSize: 18)),
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
