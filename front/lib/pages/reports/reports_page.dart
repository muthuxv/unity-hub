import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportsPage extends StatefulWidget {
  final String serverID;

  ReportsPage({required this.serverID});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<dynamic> _pendingReports = [];
  List<dynamic> _finishedReports = [];
  bool _isLoading = true;
  String _currentStatus = 'pending'; // Par défaut, filtre sur "pending"

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      final responsePending = await Dio().get(
          '$apiPath/servers/${widget.serverID}/reports/pending'
      );
      final responseFinished = await Dio().get(
          '$apiPath/servers/${widget.serverID}/reports/finished'
      );
      if (responsePending.statusCode == 200 && responseFinished.statusCode == 200) {
        setState(() {
          _pendingReports = responsePending.data['data'];
          _finishedReports = responseFinished.data['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch reports')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onStatusChanged(String? newStatus) {
    if (newStatus != null) {
      setState(() {
        _currentStatus = newStatus;
      });
    }
  }

  Future<void> _showReportActions(BuildContext context, dynamic report) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Actions'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('What would you like to do?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Delete Message'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMessage(report['MessageID']);
                await _updateReportStatus(report['ID'], 'finished');
                _fetchReports();
              },
            ),
            TextButton(
              child: Text('Delete Report'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteReport(report['ID']);
                _fetchReports();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().put(
        '$apiPath/messages/$messageId',
        data: {'Content': 'Ce message a été supprimé après signalement'},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating message: $e')),
      );
    }
  }

  Future<void> _deleteReport(String reportId) async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().delete('$apiPath/reports/$reportId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    await dotenv.load();
    final apiPath = dotenv.env['API_PATH']!;

    try {
      await Dio().put(
        '$apiPath/reports/$reportId',
        data: {'status': status},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> displayedReports =
    _currentStatus == 'pending' ? _pendingReports : _finishedReports;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        backgroundColor: Color(0xFF643869),
        actions: [
          DropdownButton<String>(
            value: _currentStatus,
            onChanged: _onStatusChanged,
            items: [
              DropdownMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: 'finished',
                child: Text('Finished'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF643869), Color(0xFF2385C6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildReportsSection(
          _currentStatus == 'pending' ? 'Pending Reports' : 'Finished Reports',
          displayedReports,
          _currentStatus == 'pending',
        ),
      ),
    );
  }

  Widget _buildReportsSection(String title, List<dynamic> reports, bool isPending) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final reportedMessage = report['ReportedMessage'];
              final reporter = report['Reporter'];

              return GestureDetector(
                onTap: isPending
                    ? () => _showReportActions(context, report)
                    : null,
                child: Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message: ${report['Message']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Status: ${report['Status']}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Reported Message: ${reportedMessage['Content']}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Reported by: ${reporter['Pseudo']}',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
