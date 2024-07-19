// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m0(count) =>
      "${Intl.plural(count, one: 'Bouton', other: 'Boutons')}";

  static String m1(count) =>
      "${Intl.plural(count, one: 'Couleur', other: 'Couleurs')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Dialogue', other: 'Dialogues')}";

  static String m3(value) =>
      "La valeur de ce champ doit être égale à ${value}.";

  static String m4(count) =>
      "${Intl.plural(count, one: 'Extension', other: 'Extensions')}";

  static String m5(count) =>
      "${Intl.plural(count, one: 'Formulaire', other: 'Formulaires')}";

  static String m6(max) => "La valeur doit être inférieure ou égale à ${max}.";

  static String m7(maxLength) =>
      "La valeur doit avoir une longueur inférieure ou égale à ${maxLength}.";

  static String m8(min) => "La valeur doit être supérieure ou égale à ${min}.";

  static String m9(minLength) =>
      "La valeur doit avoir une longueur supérieure ou égale à ${minLength}.";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Nouvelle Commande', other: 'Nouvelles Commandes')}";

  static String m11(count) =>
      "${Intl.plural(count, one: 'Nouvel Utilisateur', other: 'Nouveaux Utilisateurs')}";

  static String m12(value) =>
      "La valeur de ce champ ne doit pas être égale à ${value}.";

  static String m13(count) =>
      "${Intl.plural(count, one: 'Page', other: 'Pages')}";

  static String m14(count) =>
      "${Intl.plural(count, one: 'Problème en attente', other: 'Problèmes en attente')}";

  static String m15(count) =>
      "${Intl.plural(count, one: 'Commande Récente', other: 'Commandes Récentes')}";

  static String m16(count) =>
      "${Intl.plural(count, one: 'Élément UI', other: 'Éléments UI')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "account": MessageLookupByLibrary.simpleMessage("Compte"),
        "adminPortalLogin": MessageLookupByLibrary.simpleMessage(
            "Connexion au Portail Administrateur"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Administration Web"),
        "backToLogin":
            MessageLookupByLibrary.simpleMessage("Retour à la connexion"),
        "buttonEmphasis":
            MessageLookupByLibrary.simpleMessage("Mise en avant du bouton"),
        "buttons": m0,
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "closeNavigationMenu": MessageLookupByLibrary.simpleMessage(
            "Fermer le menu de navigation"),
        "colorPalette":
            MessageLookupByLibrary.simpleMessage("Palette de couleurs"),
        "colorScheme":
            MessageLookupByLibrary.simpleMessage("Schème de couleurs"),
        "colors": m1,
        "confirmDeleteRecord": MessageLookupByLibrary.simpleMessage(
            "Confirmer la suppression de cet enregistrement ?"),
        "confirmSubmitRecord": MessageLookupByLibrary.simpleMessage(
            "Confirmer la soumission de cet enregistrement ?"),
        "copy": MessageLookupByLibrary.simpleMessage("Copier"),
        "creditCardErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite un numéro de carte de crédit valide."),
        "crudBack": MessageLookupByLibrary.simpleMessage("Retour"),
        "crudDelete": MessageLookupByLibrary.simpleMessage("Supprimer"),
        "crudDetail": MessageLookupByLibrary.simpleMessage("Détail"),
        "crudNew": MessageLookupByLibrary.simpleMessage("Nouveau"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Thème sombre"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Tableau de bord"),
        "dateStringErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite une chaîne de date valide."),
        "dialogs": m2,
        "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez pas de compte ?"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite une adresse email valide."),
        "equalErrorText": m3,
        "error404": MessageLookupByLibrary.simpleMessage("Erreur 404"),
        "error404Message": MessageLookupByLibrary.simpleMessage(
            "Désolé, la page que vous recherchez a été supprimée ou n\'existe pas."),
        "error404Title":
            MessageLookupByLibrary.simpleMessage("Page non trouvée"),
        "example": MessageLookupByLibrary.simpleMessage("Exemple"),
        "extensions": m4,
        "forms": m5,
        "generalUi": MessageLookupByLibrary.simpleMessage("UI Générale"),
        "hi": MessageLookupByLibrary.simpleMessage("Salut"),
        "homePage": MessageLookupByLibrary.simpleMessage("Accueil"),
        "iframeDemo": MessageLookupByLibrary.simpleMessage("Démo IFrame"),
        "integerErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite un entier valide."),
        "ipErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite une adresse IP valide."),
        "language": MessageLookupByLibrary.simpleMessage("Langue"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Thème clair"),
        "login": MessageLookupByLibrary.simpleMessage("Connexion"),
        "loginNow":
            MessageLookupByLibrary.simpleMessage("Connectez-vous maintenant !"),
        "logout": MessageLookupByLibrary.simpleMessage("Déconnexion"),
        "loremIpsum": MessageLookupByLibrary.simpleMessage(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit"),
        "matchErrorText": MessageLookupByLibrary.simpleMessage(
            "La valeur ne correspond pas au motif."),
        "maxErrorText": m6,
        "maxLengthErrorText": m7,
        "minErrorText": m8,
        "minLengthErrorText": m9,
        "myProfile": MessageLookupByLibrary.simpleMessage("Mon Profil"),
        "newOrders": m10,
        "newUsers": m11,
        "notEqualErrorText": m12,
        "numericErrorText": MessageLookupByLibrary.simpleMessage(
            "La valeur doit être numérique."),
        "openInNewTab": MessageLookupByLibrary.simpleMessage(
            "Ouvrir dans un nouvel onglet"),
        "pages": m13,
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordHelperText":
            MessageLookupByLibrary.simpleMessage("* 6 - 18 caractères"),
        "passwordNotMatch": MessageLookupByLibrary.simpleMessage(
            "Les mots de passe ne correspondent pas."),
        "pendingIssues": m14,
        "recentOrders": m15,
        "recordDeletedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Enregistrement supprimé avec succès."),
        "recordSavedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Enregistrement sauvegardé avec succès."),
        "recordSubmittedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Enregistrement soumis avec succès."),
        "register": MessageLookupByLibrary.simpleMessage("S\'inscrire"),
        "registerANewAccount":
            MessageLookupByLibrary.simpleMessage("Créer un nouveau compte"),
        "registerNow":
            MessageLookupByLibrary.simpleMessage("Inscrivez-vous maintenant !"),
        "requiredErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ ne peut pas être vide."),
        "retypePassword":
            MessageLookupByLibrary.simpleMessage("Retaper le mot de passe"),
        "save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
        "search": MessageLookupByLibrary.simpleMessage("Rechercher"),
        "submit": MessageLookupByLibrary.simpleMessage("Soumettre"),
        "text": MessageLookupByLibrary.simpleMessage("Texte"),
        "textEmphasis":
            MessageLookupByLibrary.simpleMessage("Mise en avant du texte"),
        "textTheme": MessageLookupByLibrary.simpleMessage("Thème de texte"),
        "todaySales": MessageLookupByLibrary.simpleMessage("Ventes du jour"),
        "typography": MessageLookupByLibrary.simpleMessage("Typographie"),
        "uiElements": m16,
        "urlErrorText": MessageLookupByLibrary.simpleMessage(
            "Ce champ nécessite une adresse URL valide."),
        "username": MessageLookupByLibrary.simpleMessage("Nom d\'utilisateur"),
        "yes": MessageLookupByLibrary.simpleMessage("Oui")
      };
}
