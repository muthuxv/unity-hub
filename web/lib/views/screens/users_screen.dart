import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:flutter_svg/svg.dart';
import 'package:random_avatar/random_avatar.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormBuilderState>();

  late DataSource _dataSource;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataSource = DataSource(
      onDetailButtonPressed: (data) => GoRouter.of(context).go('${RouteUri.crudDetailUser}?id=${data['id']}'),
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
      title: 'Voulez-vous vraiment supprimer cet utilisateur ?',
      width: kDialogWidth,
      btnOkText: 'Oui',
      btnOkOnPress: () => _doDelete(context, data['id'].toString()),
      btnCancelText: 'Annuler',
      btnCancelOnPress: () {},
    );

    dialog.show();
  }

  void _doDelete(BuildContext context, String userId) async {
    final lang = Lang.of(context);
    try {
      final response = await Dio().delete('${env.apiBaseUrl}/users/$userId');
      if (response.statusCode == 204) {
        final dialog = AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Utilisateur supprimé avec succès',
          width: kDialogWidth,
          btnOkText: 'OK',
          btnOkOnPress: () {
            _dataSource.loadData();
          },
        );

        dialog.show();
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
      final dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Erreur lors de la suppression de l\'utilisateur',
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
          ? Center(child: CircularProgressIndicator()) // Afficher un indicateur de chargement
          : ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Text(
            'Utilisateurs',
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: kDefaultPadding * 2.0),
                          child: FormBuilder(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.disabled,
                            child: SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                direction: Axis.horizontal,
                                spacing: kDefaultPadding,
                                runSpacing: kDefaultPadding,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 40.0,
                                        child: ElevatedButton(
                                          style: themeData.extension<AppButtonTheme>()!.successElevated,
                                          onPressed: () => GoRouter.of(context).go(RouteUri.createUser),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(right: kDefaultPadding * 0.5),
                                                child: Icon(
                                                  Icons.add,
                                                  size: (themeData.textTheme.labelLarge!.fontSize! + 4.0),
                                                ),
                                              ),
                                              Text('Ajouter un utilisateur'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                                          DataColumn(label: Text('Image de profil')),
                                          DataColumn(label: Text('Pseudo')),
                                          DataColumn(label: Text('Email')),
                                          DataColumn(label: Text('Rôle')),
                                          DataColumn(label: Text('Vérifié')),
                                          DataColumn(label: Text('Créé le')),
                                          DataColumn(label: Text('Modifié le')),
                                          DataColumn(label: Text('Supprimé le')),
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

class DataSource extends DataTableSource {
  final void Function(Map<String, dynamic> data) onDetailButtonPressed;
  final void Function(Map<String, dynamic> data) onDeleteButtonPressed;

  List<Map<String, dynamic>> _data = []; // Updated to store API data

  DataSource({
    required this.onDetailButtonPressed,
    required this.onDeleteButtonPressed,
  });

  Future<void> loadData() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    try {
      final response = await Dio().get('${env.apiBaseUrl}/users',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        List<dynamic> users = response.data;
        _data = List.generate(users.length, (index) {
          return {
            'id': users[index]['ID'],
            'pseudo': users[index]['Pseudo'],
            'email': users[index]['Email'],
            'role': users[index]['Role'],
            'isVerified': users[index]['IsVerified'],
            'createdAt': users[index]['CreatedAt'],
            'updatedAt': users[index]['UpdatedAt'],
            'deletedAt': users[index]['DeletedAt'],
            'profile': users[index]['Profile'],
          };
        });
        notifyListeners(); // Notify DataTable that data has changed
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
      DataCell(
        CircleAvatar(
          radius: 55,
          child: data['profile'].contains('<svg')
              ? SvgPicture.string(
            data['profile'],
            height: 120,
            width: 120,
          )
              : CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(data['profile']),
          ),
        ),
      ),
      DataCell(Text(data['pseudo'].toString())),
      DataCell(Text(data['email'].toString())),
      DataCell(Text(data['role'].toString())),
      DataCell(Icon(data['isVerified'] ? Icons.check : Icons.close)),
      DataCell(Text(formatDateTime(data['createdAt']))),
      DataCell(Text(formatDateTime(data['updatedAt']))),
      DataCell(Text(formatDateTime(data['deletedAt']))),
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
                  child: Text('Modifier'),
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
