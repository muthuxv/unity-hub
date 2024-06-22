import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:go_router/go_router.dart';
import 'package:web_admin/app_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/constants/dimens.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/theme/theme_extensions/app_button_theme.dart';
import 'package:web_admin/theme/theme_extensions/app_color_scheme.dart';
import 'package:web_admin/theme/theme_extensions/app_data_table_theme.dart';
import 'package:web_admin/views/widgets/card_elements.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dataTableHorizontalScrollController = ScrollController();
  int serverCount = 0;
  int userCount = 0;
  int tagCount = 0;
  List<dynamic> recentUsersData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch both server and user counts when the widget is initialized
  }

  Future<void> fetchData() async {
    try {
      final dio = Dio();
      final serverResponse = await dio.get('http://localhost:8080/servers');
      final userResponse = await dio.get('http://localhost:8080/users');
      final tagResponse = await dio.get('http://localhost:8080/tags');

      if (serverResponse.statusCode == 200 &&
          userResponse.statusCode == 200 &&
          tagResponse.statusCode == 200) {
        List<dynamic> servers = serverResponse.data;
        List<dynamic> users = userResponse.data;
        List<dynamic> tags = tagResponse.data;

        // Filter users created within the last 30 days
        final now = DateTime.now();
        final recentUsers = users.where((user) {
          final createdAt = DateTime.parse(user['CreatedAt']);
          return now.difference(createdAt).inDays <= 30;
        }).toList();

        setState(() {
          serverCount = servers.length;
          userCount = users.length;
          tagCount = tags.length;
          recentUsersData = recentUsers; // Store recent users data
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dataTableHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final themeData = Theme.of(context);
    final appColorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final appDataTableTheme = Theme.of(context).extension<AppDataTableTheme>()!;
    final size = MediaQuery.of(context).size;
    final summaryCardCrossAxisCount = (size.width >= kScreenWidthLg ? 3 : 2);

    return PortalMasterLayout(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Text(
            lang.dashboard,
            style: themeData.textTheme.headlineMedium,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final summaryCardWidth = ((constraints.maxWidth -
                    (kDefaultPadding * (summaryCardCrossAxisCount - 1))) /
                    summaryCardCrossAxisCount);

                return Wrap(
                  direction: Axis.horizontal,
                  spacing: kDefaultPadding,
                  runSpacing: kDefaultPadding,
                  children: [
                    SummaryCard(
                      title: 'Utilisateurs',
                      value: '$userCount',
                      icon: Icons.people_rounded,
                      backgroundColor: appColorScheme.success,
                      textColor: themeData.colorScheme.onPrimary,
                      iconColor: Colors.black12,
                      width: summaryCardWidth,
                    ),
                    SummaryCard(
                      title: 'Serveurs',
                      value: '$serverCount',
                      icon: Icons.storage_rounded,
                      backgroundColor: appColorScheme.info,
                      textColor: themeData.colorScheme.onPrimary,
                      iconColor: Colors.black12,
                      width: summaryCardWidth,
                    ),
                    SummaryCard(
                      title: 'Tags', // Update this line to appropriate title if necessary
                      value: '$tagCount', // Update this line to use tagCount
                      icon: Icons.new_label_rounded, // Update this line to appropriate icon if necessary
                      backgroundColor: appColorScheme.warning,
                      textColor: appColorScheme.buttonTextBlack,
                      iconColor: Colors.black12,
                      width: summaryCardWidth,
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardHeader(
                    title: 'Utilisateurs récents',
                    showDivider: false,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double dataTableWidth =
                        max(kScreenWidthMd, constraints.maxWidth);

                        return Scrollbar(
                          controller: _dataTableHorizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _dataTableHorizontalScrollController,
                            child: SizedBox(
                              width: dataTableWidth,
                              child: Theme(
                                data: themeData.copyWith(
                                  cardTheme: appDataTableTheme.cardTheme,
                                  dataTableTheme:
                                  appDataTableTheme.dataTableThemeData,
                                ),
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  showBottomBorder: true,
                                  columns: const [
                                    DataColumn(label: Text('Profile')),
                                    DataColumn(label: Text('Pseudo')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Rôle')),
                                    DataColumn(label: Text('Vérifié')),
                                    DataColumn(label: Text('Crée le')),
                                    DataColumn(label: Text('Modifié le')),
                                    DataColumn(label: Text('Supprimé le')),
                                  ],
                                  rows: List.generate(recentUsersData.length, (index) {
                                    final user = recentUsersData[index];
                                    final createdAt = DateTime.parse(user['CreatedAt']);
                                    final updatedAt = DateTime.parse(user['UpdatedAt']);
                                    final deletedAt = user['DeletedAt'] != null ? DateTime.parse(user['DeletedAt']) : null;

                                    return DataRow.byIndex(
                                      index: index,
                                      cells: [
                                        DataCell(Text(user['Pseudo'])),
                                        DataCell(Text(user['Pseudo'])),
                                        DataCell(Text(user['Email'])),
                                        DataCell(Text(user['Role'])),
                                        DataCell(Icon(user['IsVerified'] ? Icons.check : Icons.close)),
                                        DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(createdAt))),
                                        DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(updatedAt))),
                                        DataCell(deletedAt != null ? Text(DateFormat('dd/MM/yyyy HH:mm').format(deletedAt)) : Text('-')),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      child: SizedBox(
                        height: 40.0,
                        width: 120.0,
                        child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).go(RouteUri.users),
                          style: themeData.extension<AppButtonTheme>()!.infoElevated,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: kDefaultPadding * 0.5),
                                child: Icon(
                                  Icons.visibility_rounded,
                                  size: (themeData.textTheme.labelLarge!.fontSize! + 4.0),
                                ),
                              ),
                              const Text('Voir plus'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double width;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 120.0,
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: backgroundColor,
        child: Stack(
          children: [
            Positioned(
              top: kDefaultPadding * 0.5,
              right: kDefaultPadding * 0.5,
              child: Icon(
                icon,
                size: 80.0,
                color: iconColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: kDefaultPadding * 0.5),
                    child: Text(
                      value,
                      style: textTheme.headlineMedium!.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: textTheme.labelLarge!.copyWith(
                      color: textColor,
                    ),
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
