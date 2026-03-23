import 'package:flutter/material.dart';

class RunningPage extends StatelessWidget {
  const RunningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Running Session', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text('Total Distance', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const Text('5.24 km', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF427AFA))),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCol('Total Time', '28:14'),
                Container(width: 1, height: 40, color: Colors.grey.shade300), // Divider
                _buildStatCol('Avg Pace', "5'23\" /km"),
                Container(width: 1, height: 40, color: Colors.grey.shade300), // Divider
                _buildStatCol('Best Pace', "4'50\" /km"),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('End Run', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}