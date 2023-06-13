import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('pt_BR', null).then((_){
    runApp(HourTrackerApp());
  });
}

class HourTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hour Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<WorkDay> workDays = [];
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  final DateFormat timeFormatter = DateFormat('HH:mm', 'pt_BR');
  final TextEditingController entryTimeController = TextEditingController();
  final TextEditingController lunchTimeController = TextEditingController();
  final TextEditingController exitTimeController = TextEditingController();
  double hourlyRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkDays();
  }

  Future<void> _loadWorkDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? savedWorkDays = prefs.getStringList('workDays');
    if (savedWorkDays != null) {
      setState(() {
        workDays.addAll(savedWorkDays.map((day) => WorkDay.fromJson(day)));
      });
    }
  }

  Future<void> _saveWorkDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> workDaysJson = workDays.map((day) => day.toJson()).cast<String>().toList();
    await prefs.setStringList('workDays', workDaysJson);
  }

  void _addWorkDay() {
    final String entryTime = entryTimeController.text;
    final String lunchTime = lunchTimeController.text;
    final String exitTime = exitTimeController.text;

    if (entryTime.isNotEmpty && exitTime.isNotEmpty) {
      final WorkDay workDay = WorkDay(
        entryTime: entryTime,
        lunchTime: lunchTime,
        exitTime: exitTime,
      );

      setState(() {
        workDays.add(workDay);
        entryTimeController.clear();
        lunchTimeController.clear();
        exitTimeController.clear();
        _saveWorkDays();
      });
    }
  }

  void _removeWorkDay(int index) {
    setState(() {
      workDays.removeAt(index);
      _saveWorkDays();
    });
  }

  double _calculateTotalHours() {
    double totalHours = 0;
    for (var workDay in workDays) {
      final double workDuration = workDay.calculateWorkDuration();
      totalHours += workDuration;
    }
    return totalHours;
  }

  double _calculateTotalSalary() {
    double totalSalary = 0;
    double totalHours = _calculateTotalHours();
    totalSalary = totalHours * hourlyRate;
    return totalSalary;
  }

  void _generateMonthlyReport() {
    double totalHours = _calculateTotalHours();
    double totalSalary = _calculateTotalSalary();
    String report = 'Monthly Report:\n\n';
    report += 'Total Hours: ${totalHours.toStringAsFixed(2)}\n';
    report += 'Total Salary: ${totalSalary.toStringAsFixed(2)}\n\n';
    report += 'Work Days:\n';
    for (var workDay in workDays) {
      report += 'Entry: ${workDay.entryTime} - Lunch: ${workDay.lunchTime} - Exit: ${workDay.exitTime}\n';
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Monthly Report'),
        content: Text(report),
        actions: [
          ElevatedButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hour Tracker'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entryTimeController,
                    decoration: InputDecoration(labelText: 'Entry Time'),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    controller: lunchTimeController,
                    decoration: InputDecoration(labelText: 'Lunch Time'),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    controller: exitTimeController,
                    decoration: InputDecoration(labelText: 'Exit Time'),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            child: Text('Add Work Day'),
            onPressed: _addWorkDay,
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: workDays.length,
              itemBuilder: (ctx, index) {
                final workDay = workDays[index];
                return ListTile(
                  title: Text('Entry: ${workDay.entryTime} - Exit: ${workDay.exitTime}'),
                  subtitle: Text('Lunch: ${workDay.lunchTime}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeWorkDay(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.calculate),
        onPressed: _generateMonthlyReport,
      ),
      persistentFooterButtons: [
        ElevatedButton(
          child: Text('Set Hourly Rate'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Hourly Rate'),
                content: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      hourlyRate = double.parse(value);
                    });
                  },
                ),
                actions: [
                  ElevatedButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ElevatedButton(
                    child: Text('Save'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class WorkDay {
  final String entryTime;
  final String lunchTime;
  final String exitTime;

  WorkDay({
    required this.entryTime,
    required this.lunchTime,
    required this.exitTime,
  });

  factory WorkDay.fromJson(String json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(json));
    return WorkDay(
      entryTime: data['entryTime'],
      lunchTime: data['lunchTime'],
      exitTime: data['exitTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryTime': entryTime,
      'lunchTime': lunchTime,
      'exitTime': exitTime,
    };
  }

  double calculateWorkDuration() {
    final Duration workDuration = DateTime.parse('2023-01-01 ${exitTime}').difference(DateTime.parse('2023-01-01 ${entryTime}'));
    final Duration lunchDuration = Duration(minutes: lunchTime.isEmpty ? 0 : int.parse(lunchTime.split(':')[1]));
    final Duration totalDuration = workDuration - lunchDuration;
    return totalDuration.inMinutes / 60;
  }
}
