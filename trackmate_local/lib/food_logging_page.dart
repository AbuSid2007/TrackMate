import 'package:flutter/material.dart';

// ==========================================
// DATA MODELS (Ready for Database Integration)
// ==========================================
class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double protein, carbs, fat;
  final String servingSize;

  FoodItem({required this.id, required this.name, required this.calories, required this.protein, required this.carbs, required this.fat, required this.servingSize});

// Future method for when you connect an API:
// factory FoodItem.fromJson(Map<String, dynamic> json) { ... }
}

class LoggedFood {
  final FoodItem food;
  final int servings;

  LoggedFood({required this.food, required this.servings});
}

// ==========================================
// MAIN UI WIDGET
// ==========================================
class FoodLoggingPage extends StatefulWidget {
  const FoodLoggingPage({super.key});

  @override
  State<FoodLoggingPage> createState() => _FoodLoggingPageState();
}

class _FoodLoggingPageState extends State<FoodLoggingPage> {
  // --- STATE VARIABLES ---

  // 1. This acts as your "Online Database" of all available foods
  final List<FoodItem> _databaseFoods = [
    FoodItem(id: '1', name: 'Chicken Breast', calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6, servingSize: '100g'),
    FoodItem(id: '2', name: 'Brown Rice', calories: 112, protein: 2.6, carbs: 24.0, fat: 0.9, servingSize: '100g'),
    FoodItem(id: '3', name: 'Broccoli', calories: 34, protein: 2.8, carbs: 7.0, fat: 0.4, servingSize: '100g'),
    FoodItem(id: '4', name: 'Salmon', calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, servingSize: '100g'),
    FoodItem(id: '5', name: 'Oatmeal', calories: 68, protein: 2.4, carbs: 12.0, fat: 1.4, servingSize: '100g'),
  ];

  // 2. These represent the user's daily log (fetched from DB on load)
  final List<LoggedFood> _eatenToday = [];

  // 3. UI Interaction State
  FoodItem? _selectedFood; // Holds the food when user clicks it
  int _servingCount = 1;
  String _searchQuery = '';

  // --- MOCK API CALLS ---
  @override
  void initState() {
    super.initState();
    _fetchDailyLog(); // Simulate fetching today's data from server
  }

  Future<void> _fetchDailyLog() async {
    // In the future: final response = await http.get('api/user/log/today');
    // For now, we preload some mock data so it looks like your screenshot
    setState(() {
      _eatenToday.addAll([
        LoggedFood(food: _databaseFoods[1], servings: 2), // 2x Brown Rice
        LoggedFood(food: _databaseFoods[0], servings: 2), // 2x Chicken
        LoggedFood(food: _databaseFoods[4], servings: 1), // 1x Oatmeal
      ]);
    });
  }

  void _logFood() {
    if (_selectedFood == null) return;

    // In the future: await http.post('api/user/log', body: {...});
    setState(() {
      _eatenToday.insert(0, LoggedFood(food: _selectedFood!, servings: _servingCount));
      _selectedFood = null; // Hide the add card
      _servingCount = 1; // Reset counter
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food logged successfully!")));
  }

  // --- DYNAMIC CALCULATORS ---
  double get _totalProtein => _eatenToday.fold(0, (sum, item) => sum + (item.food.protein * item.servings));
  double get _totalCarbs => _eatenToday.fold(0, (sum, item) => sum + (item.food.carbs * item.servings));
  double get _totalFat => _eatenToday.fold(0, (sum, item) => sum + (item.food.fat * item.servings));
  int get _totalCalories => _eatenToday.fold(0, (sum, item) => sum + (item.food.calories * item.servings));

  @override
  Widget build(BuildContext context) {
    // Goals (would also come from DB)
    const double goalProtein = 150.0;
    const double goalCarbs = 200.0;
    const double goalFat = 65.0;

    // Filter list for search
    final displayFoods = _searchQuery.isEmpty
        ? _databaseFoods
        : _databaseFoods.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // 1. TODAY'S MACROS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Macros", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                _buildMacroBar('Protein', _totalProtein, goalProtein, const Color(0xFF427AFA)),
                const SizedBox(height: 12),
                _buildMacroBar('Carbs', _totalCarbs, goalCarbs, Colors.green),
                const SizedBox(height: 12),
                _buildMacroBar('Fats', _totalFat, goalFat, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. SEARCH BAR
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search for foods...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // 3. RECENTLY USED / SEARCH RESULTS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_searchQuery.isEmpty ? "Recently Used" : "Search Results", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                ...displayFoods.map((food) => _buildFoodListItem(food)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. ADD TO LOG CARD (Only shows when a food is tapped)
          if (_selectedFood != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF427AFA), width: 2) // Blue border to highlight
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add to Log", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(_selectedFood!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_selectedFood!.calories} cal • P: ${_selectedFood!.protein}g • C: ${_selectedFood!.carbs}g • F: ${_selectedFood!.fat}g', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Serving Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Servings', style: TextStyle(color: Colors.black87)),
                        Row(
                          children: [
                            IconButton(onPressed: () => setState(() { if(_servingCount > 1) _servingCount--; }), icon: const Icon(Icons.remove)),
                            Text('$_servingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(onPressed: () => setState(() => _servingCount++), icon: const Icon(Icons.add)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _selectedFood = null),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _logFood,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AFA), padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text('Log Food', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. FOODS EATEN TODAY CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Foods Eaten Today", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 16),

                // Dynamically build the list of eaten foods
                if (_eatenToday.isEmpty)
                  const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("No food logged yet!"))),

                ..._eatenToday.map((log) => _buildLoggedFoodItem(log)).toList(),

                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

                // Total Calories Bottom Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Calories', style: TextStyle(color: Colors.black54)),
                    Text('$_totalCalories cal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- HELPER UI METHODS ---

  Widget _buildMacroBar(String label, double current, double goal, Color color) {
    double progress = (current / goal).clamp(0.0, 1.0); // Prevent overflow
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            Text('${current.toStringAsFixed(1)}g / ${goal.toInt()}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        )
      ],
    );
  }

  Widget _buildFoodListItem(FoodItem food) {
    return InkWell(
      onTap: () => setState(() {
        _selectedFood = food;
        _servingCount = 1; // Reset to 1 when new food selected
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${food.calories} cal • P: ${food.protein}g • C: ${food.carbs}g • F: ${food.fat}g', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            Text(food.servingSize, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedFoodItem(LoggedFood log) {
    final food = log.food;
    // Multiply macros by servings for the display
    int totalCals = food.calories * log.servings;
    double totalP = food.protein * log.servings;
    double totalC = food.carbs * log.servings;
    double totalF = food.fat * log.servings;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalCals cal • P: ${totalP.toStringAsFixed(1)}g • C: ${totalC.toStringAsFixed(1)}g • F: ${totalF.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text('${log.servings} x ${food.servingSize}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}