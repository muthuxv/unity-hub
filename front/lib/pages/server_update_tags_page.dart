import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ServerUpdateTagsPage extends StatefulWidget {
  final String serverId;

  ServerUpdateTagsPage({Key? key, required this.serverId}) : super(key: key);

  @override
  _ServerUpdateTagsPageState createState() => _ServerUpdateTagsPageState();
}

class _ServerUpdateTagsPageState extends State<ServerUpdateTagsPage> {
  List<dynamic> _serverTags = [];
  List<dynamic> _allTags = [];

  TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServerTags();
    fetchAllTags();
  }

  Future<void> fetchServerTags() async {
    try {
      Response response =
      await Dio().get('http://10.0.2.2:8080/servers/${widget.serverId}');
      Map<String, dynamic> serverData = Map<String, dynamic>.from(response.data);
      setState(() {
        _serverTags = serverData['Tags'] ?? [];
      });
    } catch (e) {
      print('Error fetching server tags: $e');
    }
  }

  Future<void> fetchAllTags() async {
    try {
      Response response = await Dio().get('http://10.0.2.2:8080/tags');
      setState(() {
        _allTags = response.data;
      });
    } catch (e) {
      print('Error fetching all tags: $e');
    }
  }

  Future<void> updateServerTags(List<int> tagIds) async {
    try {
      Response response = await Dio().put(
        'http://10.0.2.2:8080/servers/${widget.serverId}',
        data: {'tag_ids': tagIds},
      );
      if (response.statusCode == 200) {
        print('Server tags updated successfully');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tags mis à jour'),
            content: const Text('Vos tags ont été mis à jour avec succès.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('Failed to update server tags');
      }
    } catch (e) {
      print('Error updating server tags: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff4776e6),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Modifier les tags du serveur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff4776e6), Color(0xff8e54e9)],
            stops: [0, 1],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags actuels du serveur :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: _serverTags.map<Widget>((tag) {
                return Chip(
                  label: Text(tag['Name']),
                  backgroundColor: Colors.blue,
                  labelStyle: TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
            SizedBox(height: 24.0),
            Text(
              'Sélectionner les nouveaux tags :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: _allTags.length,
                itemBuilder: (context, index) {
                  final tag = _allTags[index];
                  bool isSelected =
                  _serverTags.any((t) => t['ID'] == tag['ID']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _serverTags.removeWhere((t) => t['ID'] == tag['ID']);
                        } else {
                          _serverTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(bottom: 12.0),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      child: Text(
                        tag['Name'],
                        style: TextStyle(
                          fontSize: 16.0,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  List<int> tagIds =
                  _serverTags.map<int>((tag) => tag['ID']).toList();
                  updateServerTags(tagIds);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Mettre à jour les tags',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }
}
