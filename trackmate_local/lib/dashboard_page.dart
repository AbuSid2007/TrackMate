import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Daily Steps Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                const Text('Daily Steps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 24),
                // Custom Circular Progress Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: 0.75, // 75% complete
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF427AFA)),
                      ),
                    ),
                    const Column(
                      children: [
                        Text('7,543', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        Text('steps', style: TextStyle(color: Colors.grey)),
                        Text('75% of goal', style: TextStyle(color: Color(0xFF427AFA), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Goal: 10,000 steps', style: TextStyle(color: Colors.black87)),
                const Text('2,457 steps to go!', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Calorie Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calorie Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 16),

                // Calories Eaten
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.restaurant, color: Colors.orange, size: 20)),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('Calories Eaten', style: TextStyle(color: Colors.black54))),
                      const Text('0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      const Text(' kcal', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Calories Burned
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.local_fire_department, color: Colors.green, size: 20)),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('Calories Burned', style: TextStyle(color: Colors.black54))),
                      const Text('2,200', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      const Text(' kcal', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),

                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

                // Net Balance
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('+2,200 kcal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(child: Text("You're in a caloric deficit - great for weight loss!", style: TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Water & Active Time Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: const Column(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 32),
                      SizedBox(height: 16),
                      Text('1.8L', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Water Intake', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: const Column(
                    children: [
                      Icon(Icons.bolt, color: Colors.orange, size: 32),
                      SizedBox(height: 16),
                      Text('45min', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Active Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}