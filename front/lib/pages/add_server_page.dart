import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddServerPage extends StatefulWidget {
  final Function(Map)? onServerAdded; // Modify to accept callback with Map
  const AddServerPage({Key? key, this.onServerAdded}) : super(key: key);

  @override
  State<AddServerPage> createState() => _AddServerPageState();
}

class _AddServerPageState extends State<AddServerPage> {
  bool _isLoading = false;
  final TextEditingController _serverNameController = TextEditingController();
  String _visibility = 'private';

  Future<void> _addServer() async {
    setState(() {
      _isLoading = true;
    });

    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    final response = await Dio().post(
      'http://10.0.2.2:8080/servers/create',
      data: {
        'name': _serverNameController.text,
        'visibility': _visibility,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context);
      final newServer = response.data['data'];
      widget.onServerAdded?.call(newServer);
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Une erreur s\'est produite lors de la création du serveur.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();

  void _showInvitationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rentrez votre lien invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Lien invitation',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un lien';
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      _joinServer(_linkController.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Rejoindre'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _joinServer(String link) async {

    setState(() {
      _isLoading = true;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await Dio().post(
        link,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez rejoint le serveur avec succès'),
          ),
        );
      } else {
        final errorMessage = response.data['error'] ?? 'Une erreur est survenue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue lors de la connexion au serveur'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4776e6), Color(0xff8e54e9)],
              stops: [0, 1],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 100),
            child: Column(
              children: [
                const Text(
                  'Créer ton propre serveur!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'lib/images/unitylog.png',
                  width: 100,
                  color: Colors.white,
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Donne un nom à ton serveur et choisis sa visibilité.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                //radio buttons for visibility
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Radio(
                            fillColor: MaterialStateProperty.all(Colors.white),
                            value: 'public',
                            groupValue: _visibility,
                            onChanged: (value) {
                              setState(() {
                                _visibility = 'public';
                              });
                            },
                          ),
                          const Text(
                            'Créer un serveur public pour tout le monde.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Radio(
                            fillColor: MaterialStateProperty.all(Colors.white),
                            value: 'private',
                            groupValue: _visibility,
                            onChanged: (value) {
                              setState(() {
                                _visibility = 'private';
                              });
                            },
                          ),
                          const Text(
                            'Créer un serveur privé pour toi et tes amis.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _serverNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom du serveur',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _addServer,
                  child: const Text('Créer le serveur'),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(
                  color: Colors.white,
                  indent: 100,
                  endIndent: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tu as déjà un code d\'invitation?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showInvitationDialog(context);
                  },
                  child: const Text('Rejoindre le serveur'),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}