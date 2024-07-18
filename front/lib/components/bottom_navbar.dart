import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyBottomNavBar extends StatelessWidget {
  final Function(int)? onTabChange;
  final int notificationCount;

  const MyBottomNavBar({super.key, required this.onTabChange, required this.notificationCount});

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
            icon: Icons.message_rounded,
            text: AppLocalizations.of(context)!.messages_tab,
          ),
          GButton(
            icon: Icons.notifications,
            text: AppLocalizations.of(context)!.notifications_tab,
            leading: notificationCount > 0
                ? Stack(
              children: [
                Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            )
                : Icon(Icons.notifications),
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