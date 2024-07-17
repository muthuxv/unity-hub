import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_admin/app_router.dart';
import 'package:web_admin/constants/dimens.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/environment.dart';
import 'package:web_admin/theme/theme_extensions/app_button_theme.dart';
import 'package:web_admin/theme/theme_extensions/app_data_table_theme.dart';
import 'package:web_admin/views/widgets/card_elements.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => LogsScreenState();
}

class LogsScreenState extends State<LogsScreen> {
  final _scrollController = ScrollController();

  late LogDataSource _dataSource;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataSource = LogDataSource(
      onDetailButtonPressed: (data) => GoRouter.of(context).go('${RouteUri.crudDetailFeature}?id=${data['id']}'),
      onDeleteButtonPressed: (data) => _confirmDelete(context, data),
    );
    _dataSource.loadData().then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> data) {
    final lang = Lang.of(context);

    final dialog = AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      title: 'Voulez-vous vraiment supprimer ce log ?',
      width: kDialogWidth,
      btnOkText: 'Oui',
      btnOkOnPress: () => _doDelete(context, data['id'].toString()),
      btnCancelText: 'Annuler',
      btnCancelOnPress: () {},
    );

    dialog.show();
  }

  void _doDelete(BuildContext context, String logId) async {
    final lang = Lang.of(context);
    try {
      final response = await Dio().delete('${env.apiBaseUrl}/logs/$logId');
      if (response.statusCode == 204) {
        final dialog = AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Log supprimé avec succès',
          width: kDialogWidth,
          btnOkText: 'OK',
          btnOkOnPress: () {
            _dataSource.loadData();
          },
        );

        dialog.show();
      } else {
        throw Exception('Failed to delete log');
      }
    } catch (e) {
      print('Error deleting log: $e');
      final dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Erreur lors de la suppression de ce log',
        width: kDialogWidth,
        btnOkText: 'OK',
        btnOkOnPress: () {},
      );

      dialog.show();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appDataTableTheme = themeData.extension<AppDataTableTheme>()!;

    return PortalMasterLayout(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Text(
            'Logs',
            style: themeData.textTheme.headlineMedium,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double dataTableWidth = max(kScreenWidthMd, constraints.maxWidth);

                              return Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _scrollController,
                                  child: SizedBox(
                                    width: dataTableWidth,
                                    child: Theme(
                                      data: themeData.copyWith(
                                        cardTheme: appDataTableTheme.cardTheme,
                                        dataTableTheme: appDataTableTheme.dataTableThemeData,
                                      ),
                                      child: PaginatedDataTable(
                                        source: _dataSource,
                                        rowsPerPage: 20,
                                        showCheckboxColumn: false,
                                        showFirstLastButtons: true,
                                        columns: const [
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Message')),
                                          DataColumn(label: Text('Server name')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

Future<String> getServerName(String serverId) async {
  try {
    final response = await Dio().get('${env.apiBaseUrl}/servers/$serverId');
    if (response.statusCode == 200) {
      return response.data['Name'] as String;
    } else {
      throw Exception('Failed to load server name');
    }
  } catch (e) {
    print('Error loading server name: $e');
    return 'Unknown';
  }
}

class LogDataSource extends DataTableSource {
  final void Function(Map<String, dynamic> data) onDetailButtonPressed;
  final void Function(Map<String, dynamic> data) onDeleteButtonPressed;

  List<Map<String, dynamic>> _data = [];

  LogDataSource({
    required this.onDetailButtonPressed,
    required this.onDeleteButtonPressed,
  });

  Future<void> loadData() async {
    try {
      final response = await Dio().get('${env.apiBaseUrl}/logs');
      if (response.statusCode == 200) {
        List<dynamic> logs = response.data;
        _data = await Future.wait(logs.map((log) async {
          final serverName = await getServerName(log['ServerID']);
          return {
            'id': log['ID'],
            'message': log['Message'],
            'createdAt': log['CreatedAt'],
            'serverName': serverName,
          };
        }).toList());
        notifyListeners();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  DataRow? getRow(int index) {
    final data = _data[index];

    return DataRow.byIndex(index: index, cells: [
      DataCell(Text(formatDateTime(data['createdAt']))),
      DataCell(Text(data['message'].toString())),
      DataCell(Text(data['serverName'].toString())), // Utilisez serverName ici
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    DateTime dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}