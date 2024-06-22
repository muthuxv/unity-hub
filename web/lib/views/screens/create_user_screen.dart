import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:web_admin/app_router.dart';
import 'package:web_admin/constants/dimens.dart';
import 'package:web_admin/generated/l10n.dart';
import 'package:web_admin/theme/theme_extensions/app_button_theme.dart';
import 'package:web_admin/utils/app_focus_helper.dart';
import 'package:web_admin/views/widgets/card_elements.dart';
import 'package:web_admin/views/widgets/portal_master_layout/portal_master_layout.dart';

class CreateUserScreen extends StatefulWidget {
  final String id;

  const CreateUserScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _formData = {
    'pseudo': '',
    'email': '',
    'password': '',
    'profile': '',
    'role': '',
  };

  bool _isSaving = false;

  void _doSubmit(BuildContext context) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        final response = await Dio().post(
          'http://localhost:8080/users',
          data: _formData,
        );

        if (response.statusCode == 201) {
          final lang = Lang.of(context);

          final dialog = AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'Utilisateur créé avec succès',
            width: kDialogWidth,
            btnOkText: 'OK',
            btnOkOnPress: () {
              GoRouter.of(context).go(RouteUri.users);
            },
          );

          dialog.show();
        } else {
          throw Exception('Failed to create user');
        }
      } catch (e) {
        print('Error creating user: $e');
        final lang = Lang.of(context);

        final dialog = AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Erreur lors de la création de l\'utilisateur',
          desc: 'Veuillez réessayer plus tard',
          width: kDialogWidth,
          btnOkText: 'OK',
          btnOkOnPress: () {},
        );

        dialog.show();
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.of(context);
    final themeData = Theme.of(context);

    final pageTitle = 'Créer un utilisateur';

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
                    child: FormBuilder(
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
                              validator: FormBuilderValidators.required(),
                              onChanged: (value) => _formData['pseudo'] = value ?? '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
                            child: FormBuilderTextField(
                              name: 'email',
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Email',
                                border: OutlineInputBorder(),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.email(),
                              ]),
                              onChanged: (value) => _formData['email'] = value ?? '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
                            child: FormBuilderDropdown(
                              name: 'role',
                              decoration: const InputDecoration(
                                labelText: 'Rôle',
                                hintText: 'Rôle',
                                border: OutlineInputBorder(),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: FormBuilderValidators.required(),
                              items: ['user', 'admin']
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role[0].toUpperCase() + role.substring(1)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => _formData['role'] = value ?? '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
                            child: FormBuilderTextField(
                              name: 'password',
                              decoration: const InputDecoration(
                                labelText: 'Mote de passe',
                                hintText: 'Mote de passe',
                                border: OutlineInputBorder(),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                              ]),
                              obscureText: true,
                              onChanged: (value) => _formData['password'] = value ?? '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: kDefaultPadding * 2.0),
                            child: FormBuilderTextField(
                              name: 'profile',
                              decoration: const InputDecoration(
                                labelText: 'Profil',
                                hintText: 'Profil',
                                border: OutlineInputBorder(),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: FormBuilderValidators.required(),
                              onChanged: (value) => _formData['profile'] = value ?? '',
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
                                      const Text('Retour'),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 40.0,
                                child: ElevatedButton(
                                  style: themeData.extension<AppButtonTheme>()!.successElevated,
                                  onPressed: _isSaving ? null : () => _doSubmit(context),
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
                                      const Text('Enregistrer'),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
