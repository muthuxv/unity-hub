import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerLogsPage extends StatefulWidget {
  final String serverId;
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
          future: Dio().get('${dotenv.env['API_PATH']}/servers/${widget.serverId}/logs'),
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
                  return Center(
                    child: Text(AppLocalizations.of(context)!.no_logs),
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
