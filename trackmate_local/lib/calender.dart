import 'package:flutter/material.dart';

// --- MODELS ---

// Types of events user can log
enum EventType { cardio, strength, nutrition }

// Types of trainer interactions
enum TrainerSyncType { checkIn, session, milestone, none }

// Represents a single activity
class TrackMateEvent {
  final String title;
  final EventType type;

  TrackMateEvent(this.title, this.type);
}

// Represents data for a single day
class DailyData {
  final DateTime date;
  final List<TrackMateEvent> events;
  final TrainerSyncType trainerSync;
  final bool isStreakDay;

  DailyData({
    required this.date,
    this.events = const [],
    this.trainerSync = TrainerSyncType.none,
    this.isStreakDay = false,
  });
}

// --- MAIN CALENDAR WIDGET ---

class TrackMateCalendar extends StatefulWidget {
  const TrackMateCalendar({super.key});

  @override
  State<TrackMateCalendar> createState() => _TrackMateCalendarState();
}

class _TrackMateCalendarState extends State<TrackMateCalendar> {

  // Helper: Convert month number → name
  String _getMonthName(int month) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[month - 1];
  }

  // Helper: Convert weekday number → name
  String _getDayName(int day) {
    const days = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    return days[day - 1];
  }

  // Current month being displayed
  late DateTime _focusedDate;

  // Stores all calendar data (key = yyyy-mm-dd)
  late Map<String, DailyData> _calendarData;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _initializeMockData();
  }

  // Convert DateTime → String key (safe for map)
  String _key(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // Mock data for testing UI
  void _initializeMockData() {
    _calendarData = {};
    DateTime today = DateTime.now();

    // Example: previous day activity
    _calendarData[_key(today.subtract(const Duration(days: 2)))] = DailyData(
      date: today.subtract(const Duration(days: 2)),
      events: [TrackMateEvent('Run', EventType.cardio)],
      isStreakDay: true,
      trainerSync: TrainerSyncType.checkIn,
    );

    // Example: today activity
    _calendarData[_key(today)] = DailyData(
      date: today,
      events: [
        TrackMateEvent('Yoga', EventType.cardio),
        TrackMateEvent('Macros', EventType.nutrition)
      ],
      isStreakDay: true,
      trainerSync: TrainerSyncType.session,
    );
  }

  // Change month (left/right arrow)
  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrackMate Calendar')),
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekdays(),
          Expanded(child: _buildCalendar()),
        ],
      ),
    );
  }

  // Top header with month + arrows
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),

          // Month + Year display
          Text(
            "${_getMonthName(_focusedDate.month)} ${_focusedDate.year}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  // Weekday labels row
  Widget _buildWeekdays() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) => Text(d)).toList(),
    );
  }

  // Main calendar grid
  Widget _buildCalendar() {
    DateTime firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);

    // Offset to align first day correctly
    int startOffset = firstDay.weekday - 1;

    // Total days in month
    int daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;

    int totalCells = startOffset + daysInMonth;

    return GridView.builder(
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {

        // Empty cells before month starts
        if (index < startOffset) return const SizedBox();

        int day = index - startOffset + 1;
        DateTime date = DateTime(_focusedDate.year, _focusedDate.month, day);

        // Get data for this date
        DailyData data = _calendarData[_key(date)] ?? DailyData(date: date);

        return GestureDetector(
          onTap: () => _showDetail(data),
          child: _dayCell(data),
        );
      },
    );
  }

  // Individual day cell UI
  Widget _dayCell(DailyData data) {
    DateTime now = DateTime.now();

    // Check if current cell is today
    bool isToday = data.date.year == now.year &&
        data.date.month == now.month &&
        data.date.day == now.day;

    return Container(
      decoration: BoxDecoration(
        color: data.isStreakDay
            ? Colors.green.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Day number
          Text(
            '${data.date.day}',
            style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
          ),

          // Show event icons (max 2)
          if (data.events.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.events.take(2).map((e) => _icon(e.type)).toList(),
            ),

          // If more events exist
          if (data.events.length > 2)
            Text('+${data.events.length - 2}', style: const TextStyle(fontSize: 10)),

          // Trainer event indicator
          if (data.trainerSync != TrainerSyncType.none) _dot(data.trainerSync),
        ],
      ),
    );
  }

  // Icon for each event type
  Widget _icon(EventType type) {
    switch (type) {
      case EventType.cardio:
        return const Icon(Icons.directions_run, size: 14);
      case EventType.strength:
        return const Icon(Icons.fitness_center, size: 14);
      case EventType.nutrition:
        return const Icon(Icons.restaurant, size: 14);
    }
  }

  // Small colored dot for trainer events
  Widget _dot(TrainerSyncType type) {
    Color color;
    switch (type) {
      case TrainerSyncType.checkIn:
        color = Colors.purple;
        break;
      case TrainerSyncType.session:
        color = Colors.red;
        break;
      case TrainerSyncType.milestone:
        color = Colors.amber;
        break;
      case TrainerSyncType.none:
        return const SizedBox();
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Bottom sheet showing details of a day
  void _showDetail(DailyData data) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Full date display
              Text(
                "${_getDayName(data.date.weekday)}, ${_getMonthName(data.date.month)} ${data.date.day}",
              ),

              const Divider(),

              // List of events
              ...data.events.map((e) => ListTile(
                    title: Text(e.title),
                    leading: _icon(e.type),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
