import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // 0 = Overview Grid, 1 = Detailed Comparison
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- VIEW SELECTOR TOGGLE ---
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, icon: Icon(Icons.grid_view), label: Text('Overview')),
                ButtonSegment(value: 1, icon: Icon(Icons.bar_chart), label: Text('Detailed')),
              ],
              selected: {_selectedView},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedView = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.white,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: const Color(0xFF427AFA), // Trackmate Blue
              ),
            ),
          ),

          // --- CHART CONTENT AREA ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _selectedView == 0 ? _buildOverviewView() : _buildDetailedView(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: OVERVIEW GRID (From Image 1)
  // ==========================================
  Widget _buildOverviewView() {
    return Column(
      children: [
        _buildChartCard('Steps Trend', _buildStepsLineChart()),
        const SizedBox(height: 16),
        _buildChartCard('Today\'s Macro Distribution', _buildMacroPieChart()),
        const SizedBox(height: 16),
        _buildChartCard('Net Calories (Burned - Eaten)', _buildNetCaloriesBarChart()),
      ],
    );
  }

  // ==========================================
  // VIEW 2: DETAILED COMPARISON (From Image 2)
  // ==========================================
  Widget _buildDetailedView() {
    return Column(
      children: [
        _buildChartCard('Calories: Burned vs Eaten', _buildGroupedBarChart(), height: 350),
        const SizedBox(height: 16),
        const Center(
          child: Text("Swipe to Overview for more charts!", style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }

  // ==========================================
  // CHART BUILDERS
  // ==========================================

  // 1. Simple Line Chart (Steps)
  Widget _buildStepsLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value >= 0 && value < days.length) {
                  return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 8000), FlSpot(1, 10500), FlSpot(2, 7500), FlSpot(3, 9000), FlSpot(4, 11000), FlSpot(5, 6500), FlSpot(6, 8500)],
            isCurved: true,
            color: const Color(0xFF427AFA),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF427AFA).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  // 2. Pie Chart (Macros)
  Widget _buildMacroPieChart() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(color: Colors.blue, value: 68, title: '68%', radius: 70, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(color: Colors.orange, value: 25, title: '25%', radius: 70, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(color: Colors.green, value: 7, title: '7%', radius: 70, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(Colors.blue, 'Protein', '127.6g'),
            _buildLegendItem(Colors.green, 'Carbs', '14g'),
            _buildLegendItem(Colors.orange, 'Fats', '47g'),
          ],
        )
      ],
    );
  }

  // 3. Positive/Negative Bar Chart (Net Calories)
  Widget _buildNetCaloriesBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)));
                    }
                )
            )
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildNetCalorieBar(0, -200),
          _buildNetCalorieBar(1, 150),
          _buildNetCalorieBar(2, -300),
          _buildNetCalorieBar(3, -100),
          _buildNetCalorieBar(4, 200),
          _buildNetCalorieBar(5, 300),
          _buildNetCalorieBar(6, -50),
        ],
      ),
    );
  }

  BarChartGroupData _buildNetCalorieBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: const Color(0xFF26B07D), width: 20, borderRadius: BorderRadius.circular(2))],
    );
  }

  // 4. Grouped Bar Chart (Burned vs Eaten)
  Widget _buildGroupedBarChart() {
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSimpleLegend(Colors.red.shade400, 'Calories Burned'),
            const SizedBox(width: 16),
            _buildSimpleLegend(Colors.blue.shade400, 'Calories Eaten'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)));
                          }
                      )
                  )
              ),
              borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
              barGroups: [
                _buildGroup(0, 2300, 2100),
                _buildGroup(1, 1800, 1900),
                _buildGroup(2, 2400, 2200),
                _buildGroup(3, 2100, 2000),
                _buildGroup(4, 1900, 2100),
                _buildGroup(5, 2500, 2400),
                _buildGroup(6, 1700, 1700),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildGroup(int x, double burned, double eaten) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: burned, color: Colors.red.shade400, width: 12, borderRadius: BorderRadius.circular(2)),
        BarChartRodData(toY: eaten, color: Colors.blue.shade400, width: 12, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildChartCard(String title, Widget chart, {double height = 250}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 24),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSimpleLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}