import 'package:flutter/material.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        actions: <Widget>[
          // Bouton pour ajouter des amis avec un fond, une icône et une marge à droite
          Container(
            margin: const EdgeInsets.only(right: 10),  // Ajout de la marge ici
            child: TextButton.icon(
              icon: Icon(Icons.person_add, color: Colors.white), // Icône du bouton
              label: const Text(
                'Ajouter des amis',
                style: TextStyle(
                  color: Colors.white, // Couleur du texte
                ),
              ),
              onPressed: () {
                // Ici, mettez la logique pour ajouter des amis
                print('Ajouter des amis');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Couleur de fond du bouton
                padding: EdgeInsets.symmetric(horizontal: 10), // Espace horizontal dans le bouton
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des amis...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  title: Text('Ami 1'),
                ),
                ListTile(
                  title: Text('Ami 2'),
                ),
                // Ajoutez d'autres ListTile pour d'autres amis
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
