import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyBottomNavBar extends StatelessWidget {
  final Function(int)? onTabChange;

  const MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        gap: 8,
        color: Colors.grey[400],
        activeColor: Colors.grey.shade700,
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 10,
        onTabChange: (value) => onTabChange!(value),
        tabs: [
          GButton(
            icon: Icons.storage,
            text: AppLocalizations.of(context)!.servers_tab,
          ),
          GButton(
            icon: Icons.explore,
            text: AppLocalizations.of(context)!.community_tab,
          ),
          GButton(
            icon: Icons.notifications,
            text: AppLocalizations.of(context)!.notifications_tab,
          ),
          GButton(
            icon: Icons.person,
            text: AppLocalizations.of(context)!.profile_tab,
          ),
        ],
        selectedIndex: 0,
      ),
    );
  }
}
