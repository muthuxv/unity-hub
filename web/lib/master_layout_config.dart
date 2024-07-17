import 'package:flutter/material.dart';
import 'package:web_admin/app_router.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';
import 'package:web_admin/views/widgets/portal_master_layout/sidebar.dart';

final sidebarMenuConfigs = [
  SidebarMenuConfig(
    uri: RouteUri.dashboard,
    icon: Icons.dashboard_rounded,
    title: (context) => Lang.of(context).dashboard,
  ),
  SidebarMenuConfig(
    uri: RouteUri.users,
    icon: Icons.people_rounded,
    title: (context) => 'Utilisateurs',
  ),
  SidebarMenuConfig(
    uri: RouteUri.servers,
    icon: Icons.storage_rounded,
    title: (context) => 'Serveurs',
  ),
  SidebarMenuConfig(
    uri: RouteUri.tags,
    icon: Icons.label_rounded,
    title: (context) => 'Tags',
  ),
  SidebarMenuConfig(
    uri: RouteUri.featuresFlipping,
    icon: Icons.toggle_on,
    title: (context) => 'Features Flipping',
  ),
  SidebarMenuConfig(
    uri: RouteUri.logs,
    icon: Icons.remove_red_eye,
    title: (context) => 'Logs',
  ),
  SidebarMenuConfig(
    uri: RouteUri.form,
    icon: Icons.edit_note_rounded,
    title: (context) => Lang.of(context).forms(1),
  ),
];

const localeMenuConfigs = [
  LocaleMenuConfig(
    languageCode: 'en',
    name: 'English',
  ),
  LocaleMenuConfig(
    languageCode: 'zh',
    scriptCode: 'Hans',
    name: '中文 (简体)',
  ),
  LocaleMenuConfig(
    languageCode: 'zh',
    scriptCode: 'Hant',
    name: '中文 (繁體)',
  ),
];
