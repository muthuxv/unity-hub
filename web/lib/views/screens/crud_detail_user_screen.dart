import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:web_admin/app_router.dart';
import 'package:web_admin/constants/dimens.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/environment.dart';
import 'package:web_admin/theme/theme_extensions/app_button_theme.dart';
import 'package:web_admin/utils/app_focus_helper.dart';
import 'package:web_admin/views/widgets/card_elements.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CrudDetailUserScreen extends StatefulWidget {
  final String id;

  const CrudDetailUserScreen({
    super.key,
    required this.id,
  });

  @override
  State<CrudDetailUserScreen> createState() => _CrudDetailUserScreenState();
}

class _CrudDetailUserScreenState extends State<CrudDetailUserScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _formData = FormData();
  final _storage = const FlutterSecureStorage();

  Future<bool>? _future;

  Future<bool> _getDataAsync() async {
    if (widget.id.isNotEmpty) {
      try {
        final token = await _storage.read(key: 'token');

        final response = await Dio().get(
          '${env.apiBaseUrl}/users/${widget.id}',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (response.statusCode == 200) {
          final user = response.data;
          _formData.id = widget.id;
          _formData.pseudo = user['Pseudo'];
          _formData.email = user['Email'];
          _formData.role = user['Role'];
        }
      } catch (e) {
        print('Error loading user data: $e');
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
              '${env.apiBaseUrl}/users/${widget.id}/admin-update',
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                },
              ),
              data: {
                'Pseudo': _formData.pseudo,
                'Email': _formData.email,
                'Role': _formData.role,
              },
            );

            if (response.statusCode == 200) {
              final d = AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                title: 'Utilisateur modifié avec succès',
                width: kDialogWidth,
                btnOkText: 'OK',
                btnOkOnPress: () => GoRouter.of(context).go(RouteUri.users),
              );

              d.show();
            } else {
              throw Exception('Failed to update user');
            }
          } catch (e) {
            print('Error updating user: $e');
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

    final pageTitle = 'Modification de l\'utilisateur';

    return PortalMasterLayout(
      selectedMenuUri: RouteUri.users,
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
                          if (snapshot.hasData && snapshot.data!) {
                            return _content(context);
                          }
                        } else if (snapshot.hasData && snapshot.data!) {
                          return _content(context);
                        }

                        return Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
                          child: SizedBox(
                            height: 40.0,
                            width: 40.0,
                            child: CircularProgressIndicator(
                              backgroundColor: themeData.scaffoldBackgroundColor,
                            ),
                          ),
                        );
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
              name: 'pseudo',
              decoration: const InputDecoration(
                labelText: 'Pseudo',
                hintText: 'Pseudo',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              initialValue: _formData.pseudo,
              validator: FormBuilderValidators.required(),
              onSaved: (value) => (_formData.pseudo = value ?? ''),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding * 2.0),
            child: FormBuilderTextField(
              name: 'email',
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Email',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              initialValue: _formData.email,
              validator: FormBuilderValidators.required(),
              onSaved: (value) => (_formData.email = value ?? ''),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding * 2.0),
            child: FormBuilderDropdown(
              name: 'role',
              decoration: const InputDecoration(
                labelText: 'Rôle',
                hintText: 'Rôle',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              initialValue: _formData.role,
              validator: FormBuilderValidators.required(),
              onSaved: (value) => (_formData.role = value ?? ''),
              items: const [
                DropdownMenuItem(
                  value: 'admin',
                  child: Text('Admin'),
                ),
                DropdownMenuItem(
                  value: 'user',
                  child: Text('User'),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 40.0,
                child: ElevatedButton(
                  style: themeData.extension<AppButtonTheme>()!.secondaryElevated,
                  onPressed: () => GoRouter.of(context).go(RouteUri.users),
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
  String pseudo = '';
  String email = '';
  String role = '';
}
