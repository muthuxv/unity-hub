import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
            tabs: const [
              GButton(
                icon: Icons.storage,
                text: 'Serveurs',
              ),
              GButton(
                icon: Icons.explore,
                text: 'Community',
              ),
              GButton(
                icon: Icons.notifications,
                text: 'Notifications',
              ),
              GButton(
                icon: Icons.person,
                text: 'Profil',
              ),
            ],
            selectedIndex: 0,
          ),
        );
    }
}
