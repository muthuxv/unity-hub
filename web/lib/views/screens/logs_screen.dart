import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();

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
      print('Error loading data: $error');
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
    final lang = Lang.of(context);
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
                                          DataColumn(label: Text('Server ID')),
                                          DataColumn(label: Text('Actions')),
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

class LogDataSource extends DataTableSource {
  final void Function(Map<String, dynamic> data) onDetailButtonPressed;
  final void Function(Map<String, dynamic> data) onDeleteButtonPressed;

  List<Map<String, dynamic>> _data = []; // Updated to store API data

  LogDataSource({
    required this.onDetailButtonPressed,
    required this.onDeleteButtonPressed,
  });

  Future<void> loadData() async {
    try {
      final response = await Dio().get('${env.apiBaseUrl}/logs');
      if (response.statusCode == 200) {
        List<dynamic> logs = response.data;
        _data = List.generate(logs.length, (index) {
          return {
            'id': logs[index]['ID'],
            'message': logs[index]['Message'],
            'createdAt': logs[index]['CreatedAt'],
            'serverId': logs[index]['ServerID'],
          };
        });
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
      DataCell(Text(data['serverId'].toString())),
      DataCell(Builder(
        builder: (context) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: kDefaultPadding),
                child: OutlinedButton(
                  onPressed: () => onDetailButtonPressed.call(data),
                  style: Theme.of(context).extension<AppButtonTheme>()!.infoOutlined,
                  child: Text('Détails'),
                ),
              ),
              OutlinedButton(
                onPressed: () => onDeleteButtonPressed.call(data),
                style: Theme.of(context).extension<AppButtonTheme>()!.errorOutlined,
                child: Text('Supprimer'),
              ),
            ],
          );
        },
      )),
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