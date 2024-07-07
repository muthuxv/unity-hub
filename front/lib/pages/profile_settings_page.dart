import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_account_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.accountSettings,
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
                    leading: const Icon(Icons.account_circle, color: Colors.deepPurple),
                    title: Text(
                      AppLocalizations.of(context)!.account,
                      style: GoogleFonts.nunito(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileAccountPage()),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: Divider(height: 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.deepPurple),
                    title: Text(
                      AppLocalizations.of(context)!.privacyAndSecurity,
                      style: GoogleFonts.nunito(fontSize: 18),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Navigation logic for Confidentiality & Security Page
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
