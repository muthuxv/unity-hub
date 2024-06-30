import 'package:flutter/material.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Background color for the entire page
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[300], // Customizing app bar color
        title: const Text('Maintenance', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.build, // Using a construction icon
              size: 100,
              color: Colors.blue, // Icon color
            ),
            SizedBox(height: 20), // Adding some space between elements
            Text(
              'Cette fonctionnalité est actuellement en maintenance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
