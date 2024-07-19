import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ServerLogsPage extends StatefulWidget {
  final String serverId;
  const ServerLogsPage({super.key, required this.serverId});

  @override
  State<ServerLogsPage> createState() => _ServerLogsPageState();
}

class _ServerLogsPageState extends State<ServerLogsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _getToken();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Response> _fetchLogs(String? token) async {
    return Dio().get(
      '${dotenv.env['API_PATH']}/servers/${widget.serverId}/logs',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: _tokenFuture.then((token) => _fetchLogs(token)),
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
