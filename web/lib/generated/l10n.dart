// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class Lang {
  Lang();

  static Lang? _current;

  static Lang get current {
    assert(_current != null,
        'No instance of Lang was loaded. Try to initialize the Lang delegate before accessing Lang.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<Lang> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = Lang();
      Lang._current = instance;

      return instance;
    });
  }

  static Lang of(BuildContext context) {
    final instance = Lang.maybeOf(context);
    assert(instance != null,
        'No instance of Lang present in the widget tree. Did you add Lang.delegate in localizationsDelegates?');
    return instance!;
  }

  static Lang? maybeOf(BuildContext context) {
    return Localizations.of<Lang>(context, Lang);
  }

  /// `Compte`
  String get account {
    return Intl.message(
      'Compte',
      name: 'account',
      desc: '',
      args: [],
    );
  }

  /// `Connexion au Portail Administrateur`
  String get adminPortalLogin {
    return Intl.message(
      'Connexion au Portail Administrateur',
      name: 'adminPortalLogin',
      desc: '',
      args: [],
    );
  }

  /// `Administration Web`
  String get appTitle {
    return Intl.message(
      'Administration Web',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Retour à la connexion`
  String get backToLogin {
    return Intl.message(
      'Retour à la connexion',
      name: 'backToLogin',
      desc: '',
      args: [],
    );
  }

  /// `Mise en avant du bouton`
  String get buttonEmphasis {
    return Intl.message(
      'Mise en avant du bouton',
      name: 'buttonEmphasis',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Bouton} other{Boutons}}`
  String buttons(num count) {
    return Intl.plural(
      count,
      one: 'Bouton',
      other: 'Boutons',
      name: 'buttons',
      desc: '',
      args: [count],
    );
  }

  /// `Annuler`
  String get cancel {
    return Intl.message(
      'Annuler',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Fermer le menu de navigation`
  String get closeNavigationMenu {
    return Intl.message(
      'Fermer le menu de navigation',
      name: 'closeNavigationMenu',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Couleur} other{Couleurs}}`
  String colors(num count) {
    return Intl.plural(
      count,
      one: 'Couleur',
      other: 'Couleurs',
      name: 'colors',
      desc: '',
      args: [count],
    );
  }

  /// `Palette de couleurs`
  String get colorPalette {
    return Intl.message(
      'Palette de couleurs',
      name: 'colorPalette',
      desc: '',
      args: [],
    );
  }

  /// `Schème de couleurs`
  String get colorScheme {
    return Intl.message(
      'Schème de couleurs',
      name: 'colorScheme',
      desc: '',
      args: [],
    );
  }

  /// `Confirmer la suppression de cet enregistrement ?`
  String get confirmDeleteRecord {
    return Intl.message(
      'Confirmer la suppression de cet enregistrement ?',
      name: 'confirmDeleteRecord',
      desc: '',
      args: [],
    );
  }

  /// `Confirmer la soumission de cet enregistrement ?`
  String get confirmSubmitRecord {
    return Intl.message(
      'Confirmer la soumission de cet enregistrement ?',
      name: 'confirmSubmitRecord',
      desc: '',
      args: [],
    );
  }

  /// `Copier`
  String get copy {
    return Intl.message(
      'Copier',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ nécessite un numéro de carte de crédit valide.`
  String get creditCardErrorText {
    return Intl.message(
      'Ce champ nécessite un numéro de carte de crédit valide.',
      name: 'creditCardErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Retour`
  String get crudBack {
    return Intl.message(
      'Retour',
      name: 'crudBack',
      desc: '',
      args: [],
    );
  }

  /// `Supprimer`
  String get crudDelete {
    return Intl.message(
      'Supprimer',
      name: 'crudDelete',
      desc: '',
      args: [],
    );
  }

  /// `Détail`
  String get crudDetail {
    return Intl.message(
      'Détail',
      name: 'crudDetail',
      desc: '',
      args: [],
    );
  }

  /// `Nouveau`
  String get crudNew {
    return Intl.message(
      'Nouveau',
      name: 'crudNew',
      desc: '',
      args: [],
    );
  }

  /// `Thème sombre`
  String get darkTheme {
    return Intl.message(
      'Thème sombre',
      name: 'darkTheme',
      desc: '',
      args: [],
    );
  }

  /// `Tableau de bord`
  String get dashboard {
    return Intl.message(
      'Tableau de bord',
      name: 'dashboard',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ nécessite une chaîne de date valide.`
  String get dateStringErrorText {
    return Intl.message(
      'Ce champ nécessite une chaîne de date valide.',
      name: 'dateStringErrorText',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Dialogue} other{Dialogues}}`
  String dialogs(num count) {
    return Intl.plural(
      count,
      one: 'Dialogue',
      other: 'Dialogues',
      name: 'dialogs',
      desc: '',
      args: [count],
    );
  }

  /// `Vous n'avez pas de compte ?`
  String get dontHaveAnAccount {
    return Intl.message(
      'Vous n\'avez pas de compte ?',
      name: 'dontHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ nécessite une adresse email valide.`
  String get emailErrorText {
    return Intl.message(
      'Ce champ nécessite une adresse email valide.',
      name: 'emailErrorText',
      desc: '',
      args: [],
    );
  }

  /// `La valeur de ce champ doit être égale à {value}.`
  String equalErrorText(Object value) {
    return Intl.message(
      'La valeur de ce champ doit être égale à $value.',
      name: 'equalErrorText',
      desc: '',
      args: [value],
    );
  }

  /// `Erreur 404`
  String get error404 {
    return Intl.message(
      'Erreur 404',
      name: 'error404',
      desc: '',
      args: [],
    );
  }

  /// `Désolé, la page que vous recherchez a été supprimée ou n'existe pas.`
  String get error404Message {
    return Intl.message(
      'Désolé, la page que vous recherchez a été supprimée ou n\'existe pas.',
      name: 'error404Message',
      desc: '',
      args: [],
    );
  }

  /// `Page non trouvée`
  String get error404Title {
    return Intl.message(
      'Page non trouvée',
      name: 'error404Title',
      desc: '',
      args: [],
    );
  }

  /// `Exemple`
  String get example {
    return Intl.message(
      'Exemple',
      name: 'example',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Extension} other{Extensions}}`
  String extensions(num count) {
    return Intl.plural(
      count,
      one: 'Extension',
      other: 'Extensions',
      name: 'extensions',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{Formulaire} other{Formulaires}}`
  String forms(num count) {
    return Intl.plural(
      count,
      one: 'Formulaire',
      other: 'Formulaires',
      name: 'forms',
      desc: '',
      args: [count],
    );
  }

  /// `UI Générale`
  String get generalUi {
    return Intl.message(
      'UI Générale',
      name: 'generalUi',
      desc: '',
      args: [],
    );
  }

  /// `Salut`
  String get hi {
    return Intl.message(
      'Salut',
      name: 'hi',
      desc: '',
      args: [],
    );
  }

  /// `Accueil`
  String get homePage {
    return Intl.message(
      'Accueil',
      name: 'homePage',
      desc: '',
      args: [],
    );
  }

  /// `Démo IFrame`
  String get iframeDemo {
    return Intl.message(
      'Démo IFrame',
      name: 'iframeDemo',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ nécessite un entier valide.`
  String get integerErrorText {
    return Intl.message(
      'Ce champ nécessite un entier valide.',
      name: 'integerErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ nécessite une adresse IP valide.`
  String get ipErrorText {
    return Intl.message(
      'Ce champ nécessite une adresse IP valide.',
      name: 'ipErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Langue`
  String get language {
    return Intl.message(
      'Langue',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `Thème clair`
  String get lightTheme {
    return Intl.message(
      'Thème clair',
      name: 'lightTheme',
      desc: '',
      args: [],
    );
  }

  /// `Connexion`
  String get login {
    return Intl.message(
      'Connexion',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Connectez-vous maintenant !`
  String get loginNow {
    return Intl.message(
      'Connectez-vous maintenant !',
      name: 'loginNow',
      desc: '',
      args: [],
    );
  }

  /// `Déconnexion`
  String get logout {
    return Intl.message(
      'Déconnexion',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Lorem ipsum dolor sit amet, consectetur adipiscing elit`
  String get loremIpsum {
    return Intl.message(
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
      name: 'loremIpsum',
      desc: '',
      args: [],
    );
  }

  /// `La valeur ne correspond pas au motif.`
  String get matchErrorText {
    return Intl.message(
      'La valeur ne correspond pas au motif.',
      name: 'matchErrorText',
      desc: '',
      args: [],
    );
  }

  /// `La valeur doit être inférieure ou égale à {max}.`
  String maxErrorText(Object max) {
    return Intl.message(
      'La valeur doit être inférieure ou égale à $max.',
      name: 'maxErrorText',
      desc: '',
      args: [max],
    );
  }

  /// `La valeur doit avoir une longueur inférieure ou égale à {maxLength}.`
  String maxLengthErrorText(Object maxLength) {
    return Intl.message(
      'La valeur doit avoir une longueur inférieure ou égale à $maxLength.',
      name: 'maxLengthErrorText',
      desc: '',
      args: [maxLength],
    );
  }

  /// `La valeur doit être supérieure ou égale à {min}.`
  String minErrorText(Object min) {
    return Intl.message(
      'La valeur doit être supérieure ou égale à $min.',
      name: 'minErrorText',
      desc: '',
      args: [min],
    );
  }

  /// `La valeur doit avoir une longueur supérieure ou égale à {minLength}.`
  String minLengthErrorText(Object minLength) {
    return Intl.message(
      'La valeur doit avoir une longueur supérieure ou égale à $minLength.',
      name: 'minLengthErrorText',
      desc: '',
      args: [minLength],
    );
  }

  /// `Mon Profil`
  String get myProfile {
    return Intl.message(
      'Mon Profil',
      name: 'myProfile',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Nouvelle Commande} other{Nouvelles Commandes}}`
  String newOrders(num count) {
    return Intl.plural(
      count,
      one: 'Nouvelle Commande',
      other: 'Nouvelles Commandes',
      name: 'newOrders',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{Nouvel Utilisateur} other{Nouveaux Utilisateurs}}`
  String newUsers(num count) {
    return Intl.plural(
      count,
      one: 'Nouvel Utilisateur',
      other: 'Nouveaux Utilisateurs',
      name: 'newUsers',
      desc: '',
      args: [count],
    );
  }

  /// `La valeur de ce champ ne doit pas être égale à {value}.`
  String notEqualErrorText(Object value) {
    return Intl.message(
      'La valeur de ce champ ne doit pas être égale à $value.',
      name: 'notEqualErrorText',
      desc: '',
      args: [value],
    );
  }

  /// `La valeur doit être numérique.`
  String get numericErrorText {
    return Intl.message(
      'La valeur doit être numérique.',
      name: 'numericErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Ouvrir dans un nouvel onglet`
  String get openInNewTab {
    return Intl.message(
      'Ouvrir dans un nouvel onglet',
      name: 'openInNewTab',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Page} other{Pages}}`
  String pages(num count) {
    return Intl.plural(
      count,
      one: 'Page',
      other: 'Pages',
      name: 'pages',
      desc: '',
      args: [count],
    );
  }

  /// `Mot de passe`
  String get password {
    return Intl.message(
      'Mot de passe',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `* 6 - 18 caractères`
  String get passwordHelperText {
    return Intl.message(
      '* 6 - 18 caractères',
      name: 'passwordHelperText',
      desc: '',
      args: [],
    );
  }

  /// `Les mots de passe ne correspondent pas.`
  String get passwordNotMatch {
    return Intl.message(
      'Les mots de passe ne correspondent pas.',
      name: 'passwordNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Problème en attente} other{Problèmes en attente}}`
  String pendingIssues(num count) {
    return Intl.plural(
      count,
      one: 'Problème en attente',
      other: 'Problèmes en attente',
      name: 'pendingIssues',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{Commande Récente} other{Commandes Récentes}}`
  String recentOrders(num count) {
    return Intl.plural(
      count,
      one: 'Commande Récente',
      other: 'Commandes Récentes',
      name: 'recentOrders',
      desc: '',
      args: [count],
    );
  }

  /// `Enregistrement supprimé avec succès.`
  String get recordDeletedSuccessfully {
    return Intl.message(
      'Enregistrement supprimé avec succès.',
      name: 'recordDeletedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Enregistrement sauvegardé avec succès.`
  String get recordSavedSuccessfully {
    return Intl.message(
      'Enregistrement sauvegardé avec succès.',
      name: 'recordSavedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Enregistrement soumis avec succès.`
  String get recordSubmittedSuccessfully {
    return Intl.message(
      'Enregistrement soumis avec succès.',
      name: 'recordSubmittedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `S'inscrire`
  String get register {
    return Intl.message(
      'S\'inscrire',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `Créer un nouveau compte`
  String get registerANewAccount {
    return Intl.message(
      'Créer un nouveau compte',
      name: 'registerANewAccount',
      desc: '',
      args: [],
    );
  }

  /// `Inscrivez-vous maintenant !`
  String get registerNow {
    return Intl.message(
      'Inscrivez-vous maintenant !',
      name: 'registerNow',
      desc: '',
      args: [],
    );
  }

  /// `Ce champ ne peut pas être vide.`
  String get requiredErrorText {
    return Intl.message(
      'Ce champ ne peut pas être vide.',
      name: 'requiredErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Retaper le mot de passe`
  String get retypePassword {
    return Intl.message(
      'Retaper le mot de passe',
      name: 'retypePassword',
      desc: '',
      args: [],
    );
  }

  /// `Enregistrer`
  String get save {
    return Intl.message(
      'Enregistrer',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Rechercher`
  String get search {
    return Intl.message(
      'Rechercher',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Soumettre`
  String get submit {
    return Intl.message(
      'Soumettre',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Texte`
  String get text {
    return Intl.message(
      'Texte',
      name: 'text',
      desc: '',
      args: [],
    );
  }

  /// `Mise en avant du texte`
  String get textEmphasis {
    return Intl.message(
      'Mise en avant du texte',
      name: 'textEmphasis',
      desc: '',
      args: [],
    );
  }

  /// `Thème de texte`
  String get textTheme {
    return Intl.message(
      'Thème de texte',
      name: 'textTheme',
      desc: '',
      args: [],
    );
  }

  /// `Ventes du jour`
  String get todaySales {
    return Intl.message(
      'Ventes du jour',
      name: 'todaySales',
      desc: '',
      args: [],
    );
  }

  /// `Typographie`
  String get typography {
    return Intl.message(
      'Typographie',
      name: 'typography',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Élément UI} other{Éléments UI}}`
  String uiElements(num count) {
    return Intl.plural(
      count,
      one: 'Élément UI',
      other: 'Éléments UI',
      name: 'uiElements',
      desc: '',
      args: [count],
    );
  }

  /// `Ce champ nécessite une adresse URL valide.`
  String get urlErrorText {
    return Intl.message(
      'Ce champ nécessite une adresse URL valide.',
      name: 'urlErrorText',
      desc: '',
      args: [],
    );
  }

  /// `Nom d'utilisateur`
  String get username {
    return Intl.message(
      'Nom d\'utilisateur',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Oui`
  String get yes {
    return Intl.message(
      'Oui',
      name: 'yes',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<Lang> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<Lang> load(Locale locale) => Lang.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
