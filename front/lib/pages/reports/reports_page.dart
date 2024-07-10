import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ReportsPage extends StatefulWidget {
  final String serverID;

  ReportsPage({required this.serverID});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _currentStatus = 'pending';
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().get(
        'http://10.0.2.2:8080/reports/server/${widget.serverID}',
        queryParameters: {'status': _currentStatus},
      );
      if (response.statusCode == 200) {
        setState(() {
          _reports = response.data['data'];
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
      _fetchReports();
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
                await _updateReportStatus(report['ID'], 'finish');
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
    try {
      await Dio().delete('http://10.0.2.2:8080/messages/$messageId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await Dio().delete('http://10.0.2.2:8080/reports/$reportId');
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
    try {
      await Dio().put(
        'http://10.0.2.2:8080/reports/$reportId',
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
                value: 'finish',
                child: Text('Finish'),
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
            : ListView.builder(
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];
            final reportedMessage = report['ReportedMessage'];
            final reporter = report['Reporter'];

            return GestureDetector(
              onTap: _currentStatus == 'pending'
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
      ),
    );
  }
}