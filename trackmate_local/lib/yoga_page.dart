import 'package:flutter/material.dart';

class YogaPage extends StatefulWidget {
  const YogaPage({super.key});

  @override
  State<YogaPage> createState() => _YogaPageState();
}

class _YogaPageState extends State<YogaPage> {
  final List<String> _asanas = ['Downward Dog', 'Child\'s Pose', 'Warrior I', 'Warrior II', 'Tree Pose', 'Cobra Pose'];
  String? _selectedAsana = 'Downward Dog';
  final List<String> _completedAsanas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yoga Practice', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Timer Display
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Text('Practice Time', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('14:32', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Log Asana Section
            const Text('Log Asana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAsana,
                        items: _asanas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (val) => setState(() => _selectedAsana = val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedAsana != null) {
                      setState(() => _completedAsanas.add(_selectedAsana!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 32),

            // Completed List
            const Text('Completed Today', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Expanded(
              child: _completedAsanas.isEmpty
                  ? const Center(child: Text('No asanas logged yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _completedAsanas.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const Icon(Icons.self_improvement, color: Colors.teal),
                      title: Text(_completedAsanas[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}