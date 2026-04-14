import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/attendance_record.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AttendanceRecord> _records = [];

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await DatabaseService.getRecords();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: _buildGradientTitle(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendar(),
              const SizedBox(height: 30),
              _buildSectionHeader("TODAY"),
              _buildClockCardDynamic("CLOCK IN", "Today"),
              const SizedBox(height: 20),
              _buildSectionHeader("YESTERDAY"),
              _buildClockCardDynamic("CLOCK OUT", "Yesterday"),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientTitle() {
    String monthYear = DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase();
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
      child: Text(
        monthYear,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      headerVisible: false,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.white),
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      calendarBuilders: CalendarBuilders(
        todayBuilder: (context, day, focusedDay) => _pillDecoration(day, brandGradient),
        selectedBuilder: (context, day, focusedDay) => _pillDecoration(day, brandGradient),
      ),
    );
  }

  Widget _pillDecoration(DateTime day, List<Color> colors) {
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '${day.day}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildClockCardDynamic(String label, String day) {
    final now = DateTime.now();
    AttendanceRecord? record;
    
    if (day == "Today") {
      record = _records.firstWhereOrNull((r) => r.timestamp.day == now.day && r.timestamp.month == now.month && r.timestamp.year == now.year && r.shiftType == label);
    } else if (day == "Yesterday") {
      final yesterday = now.subtract(const Duration(days: 1));
      record = _records.firstWhereOrNull((r) => r.timestamp.day == yesterday.day && r.timestamp.month == yesterday.month && r.timestamp.year == yesterday.year && r.shiftType == label);
    }

    final time = record != null ? DateFormat('h:mm a').format(record.timestamp) : "No data";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC4C4C4),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(colors: brandGradient).createShader(bounds),
              child: Text(
                label.replaceFirst(" ", "\n"),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 0.9),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

extension on List<AttendanceRecord> {
  AttendanceRecord? firstWhereOrNull(bool Function(AttendanceRecord) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
