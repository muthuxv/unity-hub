import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ServerLogsPage extends StatefulWidget {
  final int serverId;
  const ServerLogsPage({super.key, required this.serverId});

  @override
  State<ServerLogsPage> createState() => _ServerLogsPageState();
}

class _ServerLogsPageState extends State<ServerLogsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: Dio().get('http://10.0.2.2:8080/servers/${widget.serverId}/logs'),
          builder: (context, AsyncSnapshot<Response> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
      
            if (snapshot.hasError) {
              return Center(
                child: Text('Erreur: ${snapshot.error}'),
              );
            }
      
            final logs = snapshot.data!.data['data'] as List;
      
            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('Aucun log'),
                  );
                }
                final log = logs[index];
                return ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(log['Message']),
                  subtitle: Text(log['CreatedAt']),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
