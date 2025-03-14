import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:web_admin/app_router.dart';
import 'package:web_admin/constants/dimens.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/environment.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_admin/theme/theme_extensions/app_button_theme.dart';
import 'package:web_admin/views/widgets/card_elements.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../utils/app_focus_helper.dart';

class CrudDetailFeatureScreen extends StatefulWidget {
  final String id;

  const CrudDetailFeatureScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<CrudDetailFeatureScreen> createState() => _CrudDetailFeatureScreenState();
}

class _CrudDetailFeatureScreenState extends State<CrudDetailFeatureScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _formData = FormData();
  final _storage = const FlutterSecureStorage();

  Future<bool>? _future;

  Future<bool> _getDataAsync() async {
    if (widget.id.isNotEmpty) {
      try {
        final token = await _storage.read(key: 'token');

        final response = await Dio().get(
          '${env.apiBaseUrl}/features/${widget.id}',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
        if (response.statusCode == 200) {
          final feature = response.data;
          print(feature);
          setState(() {
            _formData.id = widget.id;
            _formData.status = feature['Status'] ?? 'false';
            _formData.name = feature['Name'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading feature data: $e');
      }
    }

    return true;
  }

  void _doSubmit(BuildContext context) {
    AppFocusHelper.instance.requestUnfocus();

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      final lang = Lang.of(context);

      final dialog = AwesomeDialog(
        context: context,
        dialogType: DialogType.question,
        title: 'Confirmer la modification ?',
        width: kDialogWidth,
        btnOkText: 'Oui',
        btnOkOnPress: () async {
          try {
            final token = await _storage.read(key: 'token');

            final response = await Dio().put(
              '${env.apiBaseUrl}/features/${widget.id}',
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                },
              ),
              data: {
                'Status': _formData.status,
                'Name': _formData.name, // Assurez-vous que le nom est inclus dans les données envoyées
              },
            );

            if (response.statusCode == 200) {
              final d = AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                title: 'Fonctionnalité modifiée avec succès',
                width: kDialogWidth,
                btnOkText: 'OK',
                btnOkOnPress: () => GoRouter.of(context).go(RouteUri.featuresFlipping),
              );

              d.show();
            } else {
              throw Exception('Failed to update feature');
            }
          } catch (e) {
            print('Error updating feature: $e');
          }
        },
        btnCancelText: 'Annuler',
        btnCancelOnPress: () {},
      );

      dialog.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final themeData = Theme.of(context);

    final pageTitle = 'Modification de la fonctionnalité';

    return PortalMasterLayout(
      selectedMenuUri: RouteUri.featuresFlipping,
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          Text(
            pageTitle,
            style: themeData.textTheme.headlineMedium,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardHeader(
                    title: pageTitle,
                  ),
                  CardBody(
                    child: FutureBuilder<bool>(
                      initialData: null,
                      future: (_future ??= _getDataAsync()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: SizedBox(
                              height: 40.0,
                              width: 40.0,
                              child: CircularProgressIndicator(
                                backgroundColor: themeData.scaffoldBackgroundColor,
                              ),
                            ),
                          );
                        } else if (snapshot.hasData && snapshot.data!) {
                          return _content(context);
                        } else {
                          return Center(child: Text('Erreur de chargement des données'));
                        }
                      },
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

  Widget _content(BuildContext context) {
    final lang = Lang.of(context);
    final themeData = Theme.of(context);

    return FormBuilder(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
            child: FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Name',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              initialValue: _formData.name,
              validator: FormBuilderValidators.required(),
              onChanged: (value) {
                setState(() {
                  _formData.name = value ?? '';
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
            child: FormBuilderDropdown(
              name: 'status',
              decoration: const InputDecoration(
                labelText: 'Status',
                hintText: 'Status',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: const [
                DropdownMenuItem(value: 'true', child: Text('Activé')),
                DropdownMenuItem(value: 'false', child: Text('Désactivé')),
              ],
              initialValue: _formData.status,
              validator: FormBuilderValidators.required(),
              onChanged: (String? value) {
                setState(() {
                  _formData.status = value ?? '';
                });
              },
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 40.0,
                child: ElevatedButton(
                  style: themeData.extension<AppButtonTheme>()!.secondaryElevated,
                  onPressed: () => GoRouter.of(context).go(RouteUri.featuresFlipping),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: kDefaultPadding * 0.5),
                        child: Icon(
                          Icons.arrow_circle_left_outlined,
                          size: (themeData.textTheme.labelLarge!.fontSize! + 4.0),
                        ),
                      ),
                      Text('Retour'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 40.0,
                child: ElevatedButton(
                  style: themeData.extension<AppButtonTheme>()!.successElevated,
                  onPressed: () => _doSubmit(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: kDefaultPadding * 0.5),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: (themeData.textTheme.labelLarge!.fontSize! + 4.0),
                        ),
                      ),
                      Text('Enregistrer'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FormData {
  String id = '';
  String status = 'false';
  String name = '';
}
