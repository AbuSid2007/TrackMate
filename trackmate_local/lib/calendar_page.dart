import 'package:flutter/material.dart';

// --- MODELS ---

enum EventType { cardio, strength, nutrition }
enum TrainerSyncType { checkIn, session, milestone, none }

class TrackMateEvent {
  final String title;
  final EventType type;
  TrackMateEvent(this.title, this.type);
}

class DailyData {
  final DateTime date;
  final List<TrackMateEvent> events;
  final TrainerSyncType trainerSync;

  DailyData({
    required this.date,
    this.events = const [],
    this.trainerSync = TrainerSyncType.none,
  });
}

// --- PAGE WRAPPER ---

class TrackMateCalendarPage extends StatelessWidget {
  const TrackMateCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Calendar')),
      body: const TrackMateCalendar(),
    );
  }
}

// --- MAIN CALENDAR WIDGET ---

class TrackMateCalendar extends StatefulWidget {
  const TrackMateCalendar({super.key});

  @override
  State<TrackMateCalendar> createState() => _TrackMateCalendarState();
}

class _TrackMateCalendarState extends State<TrackMateCalendar> {
  late DateTime _focusedDate;
  late Map<String, DailyData> _calendarData;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();

    // --- Dummy Data ---
    _calendarData = {
      _key(DateTime.now()): DailyData(
        date: DateTime.now(),
        events: [
          TrackMateEvent("Morning Run", EventType.cardio),
          TrackMateEvent("Healthy Meal", EventType.nutrition),
        ],
        trainerSync: TrainerSyncType.checkIn,
      ),
      _key(DateTime.now().subtract(const Duration(days: 1))): DailyData(
        date: DateTime.now().subtract(const Duration(days: 1)),
        events: [
          TrackMateEvent("Gym Workout", EventType.strength),
        ],
      ),
    };
  }

  // --- HELPERS ---

  String _key(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _getMonthName(int month) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[month - 1];
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
    });
  }

  // --- STREAK LOGIC ---

  bool _isStreakDay(DateTime date) {
    DateTime prev = date.subtract(const Duration(days: 1));

    return _calendarData.containsKey(_key(date)) &&
        _calendarData[_key(date)]!.events.isNotEmpty &&
        _calendarData.containsKey(_key(prev)) &&
        _calendarData[_key(prev)]!.events.isNotEmpty;
  }

  // --- ICONS ---

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.cardio:
        return Icons.directions_run;
      case EventType.strength:
        return Icons.fitness_center;
      case EventType.nutrition:
        return Icons.apple;
    }
  }

  // --- TRAINER DOT ---

  Widget _buildTrainerDot(TrainerSyncType type) {
    Color? color;

    switch (type) {
      case TrainerSyncType.checkIn:
        color = Colors.purple;
        break;
      case TrainerSyncType.session:
        color = Colors.red;
        break;
      case TrainerSyncType.milestone:
        color = Colors.orange;
        break;
      case TrainerSyncType.none:
        return const SizedBox();
    }

    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // --- BOTTOM SHEET ---

  void _openDayDetails(DailyData data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${data.date.day} ${_getMonthName(data.date.month)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text("Activities:", style: TextStyle(fontWeight: FontWeight.bold)),

              if (data.events.isEmpty)
                const Text("No activities logged")
              else
                ...data.events.map((e) => ListTile(
                      leading: Icon(_getEventIcon(e.type)),
                      title: Text(e.title),
                    )),

              const SizedBox(height: 10),

              if (data.trainerSync != TrainerSyncType.none)
                Text(
                  "Trainer Event: ${data.trainerSync.name}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildWeekdays(),
            const SizedBox(height: 12),
            _buildCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left)),
        
        // Added Flexible and FittedBox here just in case the month name gets too long on tiny screens
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${_getMonthName(_focusedDate.month)} ${_focusedDate.year}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ),
        
        IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _buildWeekdays() {
    const days = ['M','T','W','T','F','S','S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Text(d,
              style: const TextStyle(color: Colors.grey, fontSize: 12)))
          .toList(),
    );
  }

  Widget _buildCalendar() {
    DateTime firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    int startOffset = firstDay.weekday - 1;
    int daysInMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: startOffset + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        if (index < startOffset) return const SizedBox();

        int day = index - startOffset + 1;
        DateTime date =
            DateTime(_focusedDate.year, _focusedDate.month, day);

        DailyData data =
            _calendarData[_key(date)] ?? DailyData(date: date);

        return _dayCell(data);
      },
    );
  }

  Widget _dayCell(DailyData data) {
    DateTime now = DateTime.now();

    bool isToday = data.date.year == now.year &&
        data.date.month == now.month &&
        data.date.day == now.day;

    bool isStreak = _isStreakDay(data.date);

    return GestureDetector(
      onTap: () => _openDayDetails(data),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isStreak
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        // FIX: Wrapped the Column in a FittedBox so it gracefully shrinks to fit the cell boundaries
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added to keep Column wrapping tightly around its children
            children: [
              Text(
                '${data.date.day}',
                style: TextStyle(
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  color:
                      isToday ? const Color(0xFF427AFA) : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: data.events.take(2).map((e) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      _getEventIcon(e.type),
                      size: 12,
                      color: Colors.black54,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 2),

              _buildTrainerDot(data.trainerSync),
            ],
          ),
        ),
      ),
    );
  }
}